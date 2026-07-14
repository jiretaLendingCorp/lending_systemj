// supabase/functions/loans/detail/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound } from "../_shared/errors.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "GET") {
      return badRequest("Method not allowed");
    }

    const authResult = await authenticateRequest(req);
    if ("error" in authResult) return authResult.error;
    const { payload } = authResult;

    const url = new URL(req.url);
    const loanId = url.pathname.split("/").filter(Boolean).pop();

    if (!loanId) {
      return badRequest("Loan ID is required");
    }

    const supabase = getServiceClient();

    const { data: loan, error: loanError } = await supabase
      .from("loans")
      .select(
        `*,
         lender:lenders!loans_lender_id_fkey(id, full_name, phone, address, kyc_status),
         co_maker:co_makers!loans_co_maker_id_fkey(id, full_name, phone, address, relationship),
         loan_schedules(id, installment_number, amount_due, due_date, status, paid_at),
         payments(id, amount, method, status, reference_number, created_at),
         disbursement:disbursements(id, method, status, delivered_at),
         approver:users!loans_approved_by_fkey(id, full_name)`
      )
      .eq("id", loanId)
      .is("deleted_at", null)
      .single();

    if (loanError || !loan) {
      return notFound("Loan");
    }

    if (hasRole(payload, "lender")) {
      const { data: lender } = await supabase
        .from('lenders')
        .select("id")
        .eq("user_id", payload.sub)
        .is("deleted_at", null)
        .single();

      if (!lender || lender.id !== loan.lender_id) {
        return forbidden("You do not have access to this loan");
      }
    }

    const totalPaid = (loan.payments ?? [])
      .filter((p: { status: string }) => p.status === "completed")
      .reduce((sum: number, p: { amount: number }) => sum + Number(p.amount), 0);

    const remainingBalance = Number(loan.total_payable) - totalPaid;

    return successResponse(
      {
        loan,
        summary: {
          principal: Number(loan.principal),
          interest_rate: Number(loan.interest_rate),
          total_payable: Number(loan.total_payable),
          total_paid: totalPaid,
          remaining_balance: Math.max(0, remainingBalance),
          penalty_amount: Number(loan.penalty_amount ?? 0),
          is_overdue: loan.due_at ? new Date(loan.due_at) < new Date() : false,
        },
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Loan detail error:", err);
    return serverError("Failed to fetch loan details");
  }
});
