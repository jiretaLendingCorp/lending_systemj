/**
 * POST /notifications/send-sms
 * Called by pg_cron, not by client. 2-days-before-due reminders.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError } from "../_shared/errors.ts";

const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";
const SMS_API_KEY = Deno.env.get("SMS_API_KEY") ?? "";
const SMS_PROVIDER = Deno.env.get("SMS_PROVIDER") ?? "semaphore";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    // Verify cron secret
    const cronSecret = req.headers.get("x-cron-secret");
    if (!cronSecret || cronSecret !== CRON_SECRET) {
      return badRequest("Invalid cron secret");
    }

    const supabase = getServiceClient();

    // Find loans due in 2 days
    const twoDaysFromNow = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000);
    const startOfDay = new Date(twoDaysFromNow);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(twoDaysFromNow);
    endOfDay.setHours(23, 59, 59, 999);

    const { data: upcomingLoans, error: fetchError } = await supabase
      .from("loans")
      .select(
        `id, total_payable, due_at,
         borrower:borrowers!loans_borrower_id_fkey(id, full_name, user_id),
         borrower_phones:borrower_phones!borrower_phones_borrower_id_fkey(phone_number)`
      )
      .eq("status", "disbursed")
      .gte("due_at", startOfDay.toISOString())
      .lte("due_at", endOfDay.toISOString())
      .is("deleted_at", null);

    if (fetchError) {
      return serverError("Failed to fetch upcoming loans");
    }

    const results: Array<{ loan_id: string; sent: boolean; error?: string }> = [];

    for (const loan of upcomingLoans ?? []) {
      try {
        // Get borrower's phone number
        const phones = loan.borrower_phones ?? [];
        const phone = phones.length > 0 ? phones[0].phone_number : null;

        if (!phone) {
          results.push({ loan_id: loan.id, sent: false, error: "No phone number" });
          continue;
        }

        const amountDue = Number(loan.total_payable).toLocaleString();
        const dueDate = new Date(loan.due_at).toLocaleDateString("en-PH");

        const message = `LendFlow Reminder: Your loan payment of ₱${amountDue} is due on ${dueDate}. Please ensure timely payment to avoid penalties.`;

        // Send SMS via provider
        let smsSent = false;
        if (SMS_API_KEY && SMS_PROVIDER === "semaphore") {
          const response = await fetch("https://api.semaphore.co/api/v4/messages", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              apikey: SMS_API_KEY,
              number: phone,
              message,
              sendername: "LendFlow",
            }),
          });
          smsSent = response.ok;
        }

        // Create in-app notification
        if (loan.borrower?.user_id) {
          await supabase.from("notifications").insert({
            user_id: loan.borrower.user_id,
            type: "payment_reminder",
            title: "Payment Due Soon",
            body: message,
          });
        }

        results.push({ loan_id: loan.id, sent: smsSent });
      } catch (err) {
        results.push({
          loan_id: loan.id,
          sent: false,
          error: err instanceof Error ? err.message : "Unknown error",
        });
      }
    }

    // Audit log
    await supabase.from("audit_logs").insert({
      user_id: null,
      user_role: "system",
      action: "sms_reminders_sent",
      new_value: {
        total: results.length,
        sent: results.filter((r) => r.sent).length,
        failed: results.filter((r) => !r.sent).length,
      },
    });

    return successResponse(
      {
        message: "SMS reminders processed",
        total: results.length,
        sent: results.filter((r) => r.sent).length,
        failed: results.filter((r) => !r.sent).length,
        results,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Send SMS error:", err);
    return serverError("Failed to send SMS reminders");
  }
});
