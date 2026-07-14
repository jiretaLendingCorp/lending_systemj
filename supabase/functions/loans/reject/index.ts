/**
 * POST /loans/:id/reject
 * Manager/admin only, reason required, audit log.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound, conflict } from "../_shared/errors.ts";
import { loanRejectSchema } from "../_shared/validation.ts";

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

    if (!hasRole(payload, "manager", "admin")) {
      return forbidden("Only managers or admins can reject loans");
    }

    const url = new URL(req.url);
    const loanId = url.pathname.split("/").filter(Boolean).pop();

    if (!loanId) {
      return badRequest("Loan ID is required");
    }

    const body = await req.json();
    const parsed = loanRejectSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { reason } = parsed.data;
    const supabase = getServiceClient();

    // Fetch current loan
    const { data: loan, error: loanError } = await supabase
      .from("loans")
      .select("id, status, borrower_id, principal")
      .eq("id", loanId)
      .is("deleted_at", null)
      .single();

    if (loanError || !loan) {
      return notFound("Loan");
    }

    // Can only reject from draft or under_review
    if (!["draft", "under_review"].includes(loan.status)) {
      return conflict(
        `Cannot reject loan in '${loan.status}' status. Only draft or under_review loans can be rejected.`
      );
    }

    const now = new Date().toISOString();

    const { error: updateError } = await supabase
      .from("loans")
      .update({
        status: "rejected",
        updated_at: now,
      })
      .eq("id", loanId)
      .in("status", ["draft", "under_review"]); // Optimistic lock

    if (updateError) {
      return serverError("Failed to reject loan");
    }

    // Create notification for borrower
    const { data: borrower } = await supabase
      .from("borrowers")
      .select("user_id")
      .eq("id", loan.borrower_id)
      .single();

    if (borrower) {
      await supabase.from("notifications").insert({
        user_id: borrower.user_id,
        type: "loan_rejected",
        title: "Loan Application Rejected",
        body: `Your loan application for ₱${Number(loan.principal).toLocaleString()} has been rejected. Reason: ${reason}`,
      });
    }

    // Audit log
    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "loan_rejected",
      old_value: { status: loan.status },
      new_value: { status: "rejected", reason, rejected_by: payload.sub },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        message: "Loan rejected",
        loan_id: loanId,
        status: "rejected",
        reason,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Loan reject error:", err);
    return serverError("Failed to reject loan");
  }
});
