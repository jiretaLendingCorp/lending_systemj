/**
 * GET /loans
 * Borrower sees own, manager/admin see all with filters.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../_shared/errors.ts";
import { loanListQuerySchema } from "../_shared/validation.ts";

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
         borrower:borrowers(id, full_name, phone),
         co_maker:co_makers(id, full_name, phone)`,
        { count: "exact" }
      )
      .is("deleted_at", null);

    // Role-based filtering
    if (hasRole(payload, "borrower")) {
      // Borrowers can only see their own loans
      const { data: borrower } = await supabase
        .from("borrowers")
        .select("id")
        .eq("user_id", payload.sub)
        .is("deleted_at", null)
        .single();

      if (!borrower) {
        return forbidden("Borrower profile not found");
      }
      query = query.eq("borrower_id", borrower.id);
    }
    // Managers and admins see all (with optional filters)

    // Apply status filter
    if (status) {
      query = query.eq("status", status);
    }

    // Apply sorting
    query = query.order(sort_by, { ascending: sort_order === "asc" });

    // Apply pagination
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
