/**
 * GET /reports/portfolio
 * Admin only — portfolio summary with key metrics.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../_shared/errors.ts";

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

    if (!hasRole(payload, "admin")) {
      return forbidden("Only admins can access portfolio reports");
    }

    const supabase = getServiceClient();

    // Total loans by status
    const { data: loanStatusCounts } = await supabase
      .from("loans")
      .select("status")
      .is("deleted_at", null);

    const statusBreakdown: Record<string, number> = {};
    for (const loan of loanStatusCounts ?? []) {
      statusBreakdown[loan.status] = (statusBreakdown[loan.status] ?? 0) + 1;
    }

    // Total portfolio value
    const { data: activeLoans } = await supabase
      .from("loans")
      .select("principal, total_payable, penalty_amount, final_balance")
      .in("status", ["disbursed", "defaulted"])
      .is("deleted_at", null);

    const totalPrincipal = (activeLoans ?? []).reduce(
      (sum, l) => sum + Number(l.principal),
      0
    );
    const totalPayable = (activeLoans ?? []).reduce(
      (sum, l) => sum + Number(l.total_payable),
      0
    );
    const totalPenalties = (activeLoans ?? []).reduce(
      (sum, l) => sum + Number(l.penalty_amount ?? 0),
      0
    );

    // Total collected
    const { data: completedPayments } = await supabase
      .from("payments")
      .select("amount, method")
      .eq("status", "completed")
      .is("deleted_at", null);

    const totalCollected = (completedPayments ?? []).reduce(
      (sum, p) => sum + Number(p.amount),
      0
    );

    const collectionByMethod: Record<string, number> = {};
    for (const payment of completedPayments ?? []) {
      collectionByMethod[payment.method] =
        (collectionByMethod[payment.method] ?? 0) + Number(payment.amount);
    }

    // Borrower count
    const { count: totalBorrowers } = await supabase
      .from("borrowers")
      .select("*", { count: "exact", head: true })
      .is("deleted_at", null);

    // Rider count
    const { count: totalRiders } = await supabase
      .from("riders")
      .select("*", { count: "exact", head: true })
      .is("deleted_at", null);

    // Disbursement stats
    const { data: disbursementStats } = await supabase
      .from("disbursements")
      .select("status")
      .is("deleted_at", null);

    const disbursementBreakdown: Record<string, number> = {};
    for (const d of disbursementStats ?? []) {
      disbursementBreakdown[d.status] = (disbursementBreakdown[d.status] ?? 0) + 1;
    }

    // Compute key ratios
    const outstandingBalance = totalPayable + totalPenalties - totalCollected;
    const collectionRate = totalPayable > 0 ? (totalCollected / totalPayable) * 100 : 0;
    const defaultRate =
      (activeLoans ?? []).length > 0
        ? ((statusBreakdown["defaulted"] ?? 0) / (activeLoans ?? []).length) * 100
        : 0;

    return successResponse(
      {
        generated_at: new Date().toISOString(),
        portfolio: {
          total_loans: loanStatusCounts?.length ?? 0,
          total_borrowers: totalBorrowers ?? 0,
          total_riders: totalRiders ?? 0,
          total_principal: totalPrincipal,
          total_payable: totalPayable,
          total_penalties: totalPenalties,
          total_collected: totalCollected,
          outstanding_balance: Math.max(0, outstandingBalance),
          collection_rate: Math.round(collectionRate * 100) / 100,
          default_rate: Math.round(defaultRate * 100) / 100,
        },
        loan_status_breakdown: statusBreakdown,
        collection_by_method: collectionByMethod,
        disbursement_breakdown: disbursementBreakdown,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Portfolio report error:", err);
    return serverError("Failed to generate portfolio report");
  }
});
