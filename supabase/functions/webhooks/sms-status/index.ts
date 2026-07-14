// supabase/functions/webhooks/sms-status/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError } from "../_shared/errors.ts";
import { smsStatusWebhookSchema } from "../_shared/validation.ts";

const SMS_WEBHOOK_SECRET = Deno.env.get("SMS_WEBHOOK_SECRET") ?? "";

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    const webhookSecret = req.headers.get("x-webhook-secret");
    if (SMS_WEBHOOK_SECRET && webhookSecret !== SMS_WEBHOOK_SECRET) {
      return badRequest("Invalid webhook secret");
    }

    const body = await req.json();
    const parsed = smsStatusWebhookSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Invalid webhook payload", parsed.error.flatten());
    }

    const { message_id, status, error_code, timestamp } = parsed.data;
    const supabase = getServiceClient();

    await supabase.from("audit_logs").insert({
      user_id: null,
      user_role: "system",
      action: `sms_$status`,
      new_value: {
        message_id,
        status,
        error_code,
        timestamp,
      },
    });

    if (status === "failed" || status === "undelivered") {
      console.warn(`SMS delivery failed: message_id=$message_id, error=$error_code`);

      const { data: admins } = await supabase
        .from("users")
        .select("id")
        .eq("role", "head_manager")
        .eq("is_active", true);

      if (admins && admins.length > 0) {
        await supabase.from("notifications").insert(
          admins.map((admin) => ({
            user_id: admin.id,
            type: "sms_delivery_failed",
            title: "SMS Delivery Failed",
            body: `SMS message $message_id failed to deliver. Error: ${error_code ?? "Unknown"}`,
          }))
        );
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("SMS status webhook error:", err);
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }
});
