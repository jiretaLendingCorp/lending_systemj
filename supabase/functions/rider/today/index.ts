// supabase/functions/rider/today/index.ts
import { handleCors, corsHeaders } from "../../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../../_shared/jwt.ts";
import { getServiceClient } from "../../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../../_shared/errors.ts";

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

    if (!hasRole(payload, "rider")) {
      return forbidden("Only riders can access today's tasks");
    }

    const supabase = getServiceClient();

    const { data: rider, error: riderError } = await supabase
      .from("riders")
      .select("id")
      .eq("user_id", payload.sub)
      .is("deleted_at", null)
      .single();

    if (riderError || !rider) {
      return forbidden("Rider profile not found");
    }

    const today = new Date();
    const startOfDay = new Date(today);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(today);
    endOfDay.setHours(23, 59, 59, 999);

    const { data: disbursements, error: disbError } = await supabase
      .from("disbursements")
      .select(
        `id, status, method, created_at,
         loan:loans!disbursements_loan_id_fkey(
           id, principal, total_payable,
           lender:lenders!loans_lender_id_fkey(id, full_name, phone, address)
         )`
      )
      .eq("assigned_rider_id", rider.id)
      .in("status", ["assigned", "in_transit"])
      .is("deleted_at", null);

    const { data: collections, error: collError } = await supabase
      .from("collections")
      .select(
        `id, status, amount, method, created_at,
         loan:loans!collections_loan_id_fkey(
           id, principal, total_payable,
           lender:lenders!collections_lender_id_fkey(id, full_name, phone, address)
         )`
      )
      .eq("assigned_rider_id", rider.id)
      .in("status", ["assigned", "in_transit"])
      .is("deleted_at", null);

    if (disbError || collError) {
      return serverError("Failed to fetch rider tasks");
    }

    const tasks = [
      ...(disbursements ?? []).map((d: any) => ({
        task_type: "disbursement" as const,
        task_id: d.id,
        status: d.status,
        method: d.method,
        amount: d.loan?.total_payable ?? 0,
        lender: d.loan?.lender ?? null,
        created_at: d.created_at,
      })),
      ...(collections ?? []).map((c: any) => ({
        task_type: "collection" as const,
        task_id: c.id,
        status: c.status,
        method: c.method,
        amount: c.amount,
        lender: c.loan?.lender ?? null,
        created_at: c.created_at,
      })),
    ];

    tasks.sort(
      (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    );

    const summary = {
      total_tasks: tasks.length,
      disbursements: (disbursements ?? []).length,
      collections: (collections ?? []).length,
      pending: tasks.filter((t) => t.status === "assigned").length,
      in_transit: tasks.filter((t) => t.status === "in_transit").length,
    };

    return successResponse(
      { tasks, summary },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Rider today error:", err);
    return serverError("Failed to fetch today's tasks");
  }
});
