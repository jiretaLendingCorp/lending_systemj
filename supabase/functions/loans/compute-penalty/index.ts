/**
 * POST /loans/:id/penalty
 * Cron-only, 30+ days overdue, 20% of total_payable, status→defaulted.
 * Called by pg_cron or authorized service account.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../_shared/errors.ts";

const PENALTY_THRESHOLD_DAYS = 30;
const PENALTY_RATE = 0.20;
const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    // Authenticate: either cron secret header or admin JWT
    const cronSecret = req.headers.get("x-cron-secret");
    let isCron = false;

    if (cronSecret && cronSecret === CRON_SECRET) {
      isCron = true;
    } else {
      const authResult = await authenticateRequest(req);
      if ("error" in authResult) return authResult.error;
      if (!hasRole(authResult.payload, "admin")) {
        return forbidden("Only admin or cron can compute penalties");
      }
    }

    const url = new URL(req.url);
    const loanId = url.pathname.split("/").filter(Boolean).pop();

    const supabase = getServiceClient();

    // If specific loan ID provided, process just that loan
    if (loanId) {
      const result = await processLoanPenalty(supabase, loanId);
      return successResponse(result, 200, corsHeaders(req));
    }

    // Otherwise, process all overdue loans (cron mode)
    if (!isCron) {
      return badRequest("Bulk penalty computation requires cron authentication");
    }

    // Find all disbursed loans that are 30+ days past due
    const thresholdDate = new Date(
      Date.now() - PENALTY_THRESHOLD_DAYS * 24 * 60 * 60 * 1000
    ).toISOString();

    const { data: overdueLoans, error: fetchError } = await supabase
      .from("loans")
      .select("id, total_payable, due_at, penalty_amount")
      .eq("status", "disbursed")
      .lt("due_at", thresholdDate)
      .is("deleted_at", null);

    if (fetchError) {
      return serverError("Failed to fetch overdue loans");
    }

    const results: Array<{ loan_id: string; penalty_applied: boolean; error?: string }> = [];

    for (const loan of overdueLoans ?? []) {
      try {
        const result = await processLoanPenalty(supabase, loan.id);
        results.push({ loan_id: loan.id, penalty_applied: true, ...result });
      } catch (err) {
        results.push({
          loan_id: loan.id,
          penalty_applied: false,
          error: err instanceof Error ? err.message : "Unknown error",
        });
      }
    }

    // Audit log for bulk operation
    await supabase.from("audit_logs").insert({
      user_id: null,
      user_role: "system",
      action: "bulk_penalty_computation",
      new_value: {
        total_processed: results.length,
        successful: results.filter((r) => r.penalty_applied).length,
        failed: results.filter((r) => !r.penalty_applied).length,
      },
    });

    return successResponse(
      {
        message: "Penalty computation completed",
        total_processed: results.length,
        results,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Penalty computation error:", err);
    return serverError("Failed to compute penalties");
  }
});

async function processLoanPenalty(
  supabase: ReturnType<typeof getServiceClient>,
  loanId: string
) {
  // Fetch the loan
  const { data: loan, error: loanError } = await supabase
    .from("loans")
    .select("id, status, total_payable, due_at, penalty_amount, borrower_id")
    .eq("id", loanId)
    .is("deleted_at", null)
    .single();

  if (loanError || !loan) {
    throw new Error(`Loan ${loanId} not found`);
  }

  // Can only penalize disbursed loans
  if (loan.status !== "disbursed") {
    return { loan_id: loanId, skipped: true, reason: `Loan status is '${loan.status}', not 'disbursed'` };
  }

  // Check if 30+ days overdue
  const dueDate = new Date(loan.due_at);
  const now = new Date();
  const daysOverdue = Math.floor(
    (now.getTime() - dueDate.getTime()) / (1000 * 60 * 60 * 24)
  );

  if (daysOverdue < PENALTY_THRESHOLD_DAYS) {
    return { loan_id: loanId, skipped: true, reason: `Only ${daysOverdue} days overdue (threshold: ${PENALTY_THRESHOLD_DAYS})` };
  }

  // Check if penalty already applied
  if (loan.penalty_amount && Number(loan.penalty_amount) > 0) {
    return { loan_id: loanId, skipped: true, reason: "Penalty already applied" };
  }

  const penaltyAmount = Number(loan.total_payable) * PENALTY_RATE;
  const finalBalance = Number(loan.total_payable) + penaltyAmount;

  const { error: updateError } = await supabase
    .from("loans")
    .update({
      penalty_amount: penaltyAmount,
      final_balance: finalBalance,
      status: "defaulted",
      defaulted_at: now.toISOString(),
      updated_at: now.toISOString(),
    })
    .eq("id", loanId)
    .eq("status", "disbursed"); // Optimistic lock

  if (updateError) {
    throw new Error(`Failed to update loan ${loanId}: ${updateError.message}`);
  }

  // Notify borrower
  const { data: borrower } = await supabase
    .from("borrowers")
    .select("user_id")
    .eq("id", loan.borrower_id)
    .single();

  if (borrower) {
    await supabase.from("notifications").insert({
      user_id: borrower.user_id,
      type: "loan_defaulted",
      title: "Loan Defaulted",
      body: `Your loan has been marked as defaulted due to ${daysOverdue} days overdue. A penalty of ₱${penaltyAmount.toLocaleString()} has been applied.`,
    });
  }

  // Audit log
  await supabase.from("audit_logs").insert({
    user_id: null,
    user_role: "system",
    action: "loan_penalty_applied",
    old_value: { status: "disbursed", penalty_amount: loan.penalty_amount },
    new_value: {
      status: "defaulted",
      penalty_amount: penaltyAmount,
      final_balance: finalBalance,
      days_overdue: daysOverdue,
    },
  });

  return {
    loan_id: loanId,
    penalty_applied: true,
    penalty_amount: penaltyAmount,
    final_balance: finalBalance,
    days_overdue: daysOverdue,
  };
}
