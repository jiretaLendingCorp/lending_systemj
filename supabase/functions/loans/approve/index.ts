/**
 * POST /loans/:id/approve
 * Manager/admin only, state transition under_review→approved, audit log.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound, conflict } from "../_shared/errors.ts";
import { loanApproveSchema } from "../_shared/validation.ts";

const VALID_TRANSITIONS: Record<string, string[]> = {
  draft: ["under_review"],
  under_review: ["approved", "rejected"],
  approved: ["disbursed"],
  disbursed: ["paid", "defaulted"],
};

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    const authResult = await authenticateRequest(req);
    if ("error" in authResult) return authResult.error;
    const { payload } = authResult;

    // Only managers and admins can approve loans
    if (!hasRole(payload, "manager", "admin")) {
      return forbidden("Only managers or admins can approve loans");
    }

    const url = new URL(req.url);
    const loanId = url.pathname.split("/").filter(Boolean).pop();

    if (!loanId) {
      return badRequest("Loan ID is required");
    }

    const body = await req.json().catch(() => ({}));
    const parsed = loanApproveSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const supabase = getServiceClient();

    // Fetch current loan
    const { data: loan, error: loanError } = await supabase
      .from("loans")
      .select("id, status, principal, interest_rate, term_days, schedule_type, borrower_id")
      .eq("id", loanId)
      .is("deleted_at", null)
      .single();

    if (loanError || !loan) {
      return notFound("Loan");
    }

    // Validate state transition
    const allowedNextStates = VALID_TRANSITIONS[loan.status] ?? [];
    if (!allowedNextStates.includes("approved")) {
      return conflict(
        `Cannot approve loan in '${loan.status}' status. Expected 'under_review'.`
      );
    }

    const now = new Date().toISOString();

    // Use the approve_loan stored procedure for atomic transition
    const { data: result, error: approveError } = await supabase.rpc("approve_loan", {
      p_loan_id: loanId,
      p_approved_by: payload.sub,
      p_approved_at: now,
    });

    if (approveError) {
      console.error("Approve loan RPC error:", approveError);
      // Fallback: direct update
      const { error: updateError } = await supabase
        .from("loans")
        .update({
          status: "approved",
          approved_by: payload.sub,
          approved_at: now,
          updated_at: now,
        })
        .eq("id", loanId)
        .eq("status", "under_review"); // Optimistic lock

      if (updateError) {
        return serverError("Failed to approve loan");
      }
    }

    // Create disbursement record
    await supabase.from("disbursements").insert({
      loan_id: loanId,
      method: "office", // Default, can be changed later
      status: "pending",
    });

    // Create notification for borrower
    const { data: borrower } = await supabase
      .from("borrowers")
      .select("user_id")
      .eq("id", loan.borrower_id)
      .single();

    if (borrower) {
      await supabase.from("notifications").insert({
        user_id: borrower.user_id,
        type: "loan_approved",
        title: "Loan Approved",
        body: `Your loan application for ₱${Number(loan.principal).toLocaleString()} has been approved.`,
      });
    }

    // Audit log
    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "loan_approved",
      old_value: { status: loan.status },
      new_value: { status: "approved", approved_by: payload.sub, approved_at: now },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        message: "Loan approved successfully",
        loan_id: loanId,
        status: "approved",
        approved_at: now,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Loan approve error:", err);
    return serverError("Failed to approve loan");
  }
});
