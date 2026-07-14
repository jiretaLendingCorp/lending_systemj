// supabase/functions/payments/list/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../_shared/errors.ts";
import { paymentListQuerySchema } from "../_shared/validation.ts";

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
    const queryParams = Object.fromEntries(url.searchParams);
    const parsed = paymentListQuerySchema.safeParse(queryParams);
    if (!parsed.success) {
      return badRequest("Invalid query parameters", parsed.error.flatten());
    }

    const { loan_id, status, page, page_size } = parsed.data;
    const supabase = getServiceClient();

    let query = supabase
      .from("payments")
      .select(
        `id, amount, method, status, reference_number, collected_at, created_at,
         loan:loans!payments_loan_id_fkey(id, principal, status, lender_id),
         lender:lenders!payments_lender_id_fkey(id, full_name, phone)`,
        { count: "exact" }
      )
      .is("deleted_at", null);

    if (hasRole(payload, "lender")) {
      const { data: lender } = await supabase
        .from('lenders')
        .select("id")
        .eq("user_id", payload.sub)
        .is("deleted_at", null)
        .single();

      if (!lender) {
        return forbidden("Lender profile not found");
      }
      query = query.eq("lender_id", lender.id);
    }

    if (loan_id) {
      query = query.eq("loan_id", loan_id);
    }
    if (status) {
      query = query.eq("status", status);
    }

    query = query.order("created_at", { ascending: false });

    const offset = (page - 1) * page_size;
    query = query.range(offset, offset + page_size - 1);

    const { data: payments, count, error: fetchError } = await query;

    if (fetchError) {
      console.error("Payment list fetch error:", fetchError);
      return serverError("Failed to fetch payments");
    }

    return successResponse(
      {
        payments: payments ?? [],
        pagination: {
          total: count ?? 0,
          page,
          pageSize: page_size,
          totalPages: Math.ceil((count ?? 0) / page_size),
        },
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Payment list error:", err);
    return serverError("Failed to fetch payments");
  }
});
