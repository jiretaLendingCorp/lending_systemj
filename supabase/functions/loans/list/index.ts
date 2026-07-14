// supabase/functions/loans/list/index.ts
import { handleCors, corsHeaders } from "../../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../../_shared/jwt.ts";
import { getServiceClient } from "../../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../../_shared/errors.ts";
import { loanListQuerySchema } from "../../_shared/validation.ts";

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
    const parsed = loanListQuerySchema.safeParse(queryParams);
    if (!parsed.success) {
      return badRequest("Invalid query parameters", parsed.error.flatten());
    }

    const { status, page, page_size, sort_by, sort_order } = parsed.data;
    const supabase = getServiceClient();

    let query = supabase
      .from("loans")
      .select(
        `id, principal, interest_rate, total_payable, term_days, schedule_type,
         status, approved_at, disbursed_at, due_at, created_at, updated_at,
         lender:lenders(id, full_name, phone),
         co_maker:co_makers(id, full_name, phone)`,
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

    if (status) {
      query = query.eq("status", status);
    }

    query = query.order(sort_by, { ascending: sort_order === "asc" });

    const offset = (page - 1) * page_size;
    query = query.range(offset, offset + page_size - 1);

    const { data: loans, count, error: fetchError } = await query;

    if (fetchError) {
      console.error("Loan list fetch error:", fetchError);
      return serverError("Failed to fetch loans");
    }

    return successResponse(
      {
        loans: loans ?? [],
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
    console.error("Loan list error:", err);
    return serverError("Failed to fetch loans");
  }
});
