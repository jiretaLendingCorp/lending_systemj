// supabase/functions/webhooks/xendit/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError } from "../_shared/errors.ts";
import { xenditWebhookSchema } from "../_shared/validation.ts";

const XENDIT_WEBHOOK_TOKEN = Deno.env.get("XENDIT_WEBHOOK_TOKEN") ?? "";

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    const webhookToken = req.headers.get("x-callback-token");
    if (!webhookToken || webhookToken !== XENDIT_WEBHOOK_TOKEN) {
      return badRequest("Invalid webhook token");
    }

    const body = await req.json();
    const parsed = xenditWebhookSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Invalid webhook payload", parsed.error.flatten());
    }

    const { id, external_id, status, amount, payment_method } = parsed.data;
    const supabase = getServiceClient();

    const { data: payment, error: paymentError } = await supabase
      .from("payments")
      .select("id, loan_id, amount, status, lender_id")
      .eq("xendit_payment_id", id)
      .maybeSingle();

    if (!payment) {
      const { data: refPayment } = await supabase
        .from("payments")
        .select("id, loan_id, amount, status, lender_id")
        .eq("reference_number", external_id)
        .maybeSingle();

      if (!refPayment) {
        console.error("Xendit webhook: Payment not found for", { id, external_id });
        return new Response(JSON.stringify({ received: true }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    const targetPayment = payment ?? (await supabase
      .from("payments")
      .select("id, loan_id, amount, status, lender_id")
      .eq("reference_number", external_id)
      .maybeSingle());

    if (!targetPayment) {
      return new Response(JSON.stringify({ received: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    let newStatus: string;
    switch (status) {
      case "PAID":
      case "SETTLED":
        newStatus = "completed";
        break;
      case "EXPIRED":
        newStatus = "failed";
        break;
      case "REFUNDED":
        newStatus = "refunded";
        break;
      case "PENDING":
        newStatus = "pending";
        break;
      default:
        newStatus = "pending";
    }

    const oldStatus = targetPayment.status;

    const { error: updateError } = await supabase
      .from("payments")
      .update({
        status: newStatus,
        ...(newStatus === "completed" && {
          collected_at: new Date().toISOString(),
        }),
      })
      .eq("id", targetPayment.id);

    if (updateError) {
      console.error("Failed to update payment status:", updateError);
      return serverError("Failed to update payment");
    }

    if (newStatus === "completed") {
      const { data: allPayments } = await supabase
        .from("payments")
        .select("amount, status")
        .eq("loan_id", targetPayment.loan_id);

      const totalPaid = (allPayments ?? [])
        .filter((p) => p.status === "completed")
        .reduce((sum, p) => sum + Number(p.amount), 0);

      const { data: loan } = await supabase
        .from("loans")
        .select("total_payable, final_balance")
        .eq("id", targetPayment.loan_id)
        .single();

      if (loan) {
        const totalPayable = Number(loan.final_balance ?? loan.total_payable);
        if (totalPaid >= totalPayable) {
          await supabase
            .from("loans")
            .update({ status: "paid", updated_at: new Date().toISOString() })
            .eq("id", targetPayment.loan_id);
        }
      }

      const { data: lender } = await supabase
        .from('lenders')
        .select("user_id")
        .eq("id", targetPayment.lender_id)
        .single();

      if (lender) {
        await supabase.from("notifications").insert({
          user_id: lender.user_id,
          type: "payment_confirmed",
          title: "Payment Confirmed",
          body: `Your payment of ₱${Number(targetPayment.amount).toLocaleString()} via ${payment_method ?? "GCash"} has been confirmed.`,
        });
      }
    }

    await supabase.from("audit_logs").insert({
      user_id: null,
      user_role: "system",
      action: "xendit_webhook_received",
      old_value: { payment_status: oldStatus },
      new_value: { payment_status: newStatus, xendit_id: id, xendit_status: status },
    });

    return new Response(JSON.stringify({ received: true, status: newStatus }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Xendit webhook error:", err);
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }
});
