// supabase/functions/reports/overdue/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../_shared/errors.ts";

const AGING_BUCKETS = [
  { label: "1-7 days", min: 1, max: 7 },
  { label: "8-15 days", min: 8, max: 15 },
  { label: "16-30 days", min: 16, max: 30 },
  { label: "31-60 days", min: 31, max: 60 },
  { label: "61-90 days", min: 61, max: 90 },
  { label: "90+ days", min: 91, max: Infinity },
];

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

    if (!hasRole(payload, "employee", "head_manager")) {
      return forbidden("Only managers or admins can access overdue reports");
    }

    const supabase = getServiceClient();

    const { data: overdueLoans, error: fetchError } = await supabase
      .from("loans")
      .select(
        `id, principal, total_payable, penalty_amount, final_balance, due_at, status,
         disbursed_at, defaulted_at,
         lender:lenders!loans_lender_id_fkey(id, full_name, phone),
         payments(id, amount, status)`
      )
      .in("status", ["disbursed", "defaulted"])
      .lt("due_at", new Date().toISOString())
      .is("deleted_at", null);

    if (fetchError) {
      return serverError("Failed to fetch overdue loans");
    }

    const now = new Date();

    const processedLoans = (overdueLoans ?? []).map((loan) => {
      const dueDate = new Date(loan.due_at);
      const daysOverdue = Math.floor(
        (now.getTime() - dueDate.getTime()) / (1000 * 60 * 60 * 24)
      );

      const totalPaid = (loan.payments ?? [])
        .filter((p: { status: string }) => p.status === "completed")
        .reduce((sum: number, p: { amount: number }) => sum + Number(p.amount), 0);

      const outstandingBalance =
        Number(loan.final_balance ?? loan.total_payable) + Number(loan.penalty_amount ?? 0) - totalPaid;

      return {
        id: loan.id,
        lender: loan.lender,
        principal: Number(loan.principal),
        total_payable: Number(loan.total_payable),
        penalty_amount: Number(loan.penalty_amount ?? 0),
        outstanding_balance: Math.max(0, outstandingBalance),
        due_at: loan.due_at,
        days_overdue: daysOverdue,
        status: loan.status,
      };
    });

    const agingBuckets = AGING_BUCKETS.map((bucket) => {
      const loans = processedLoans.filter(
        (l) => l.days_overdue >= bucket.min && l.days_overdue <= bucket.max
      );
      const totalOutstanding = loans.reduce((sum, l) => sum + l.outstanding_balance, 0);
      const totalPrincipal = loans.reduce((sum, l) => sum + l.principal, 0);

      return {
        bucket: bucket.label,
        count: loans.length,
        total_principal: totalPrincipal,
        total_outstanding: totalOutstanding,
        loans: loans.map((l) => ({
          id: l.id,
          lender: l.lender,
          principal: l.principal,
          outstanding_balance: l.outstanding_balance,
          days_overdue: l.days_overdue,
          status: l.status,
        })),
      };
    });

    const totalOverdue = processedLoans.length;
    const totalOutstandingAll = processedLoans.reduce((sum, l) => sum + l.outstanding_balance, 0);
    const totalPrincipalAll = processedLoans.reduce((sum, l) => sum + l.principal, 0);
    const defaultedCount = processedLoans.filter((l) => l.status === "defaulted").length;

    return successResponse(
      {
        generated_at: new Date().toISOString(),
        summary: {
          total_overdue_loans: totalOverdue,
          total_overdue_principal: totalPrincipalAll,
          total_outstanding_balance: totalOutstandingAll,
          defaulted_loans: defaultedCount,
          average_days_overdue:
            totalOverdue > 0
              ? Math.round(
                  (processedLoans.reduce((sum, l) => sum + l.days_overdue, 0) / totalOverdue) *
                    100
                ) / 100
              : 0,
        },
        aging_buckets: agingBuckets,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Overdue report error:", err);
    return serverError("Failed to generate overdue report");
  }
});
