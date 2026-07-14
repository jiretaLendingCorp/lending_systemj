/**
 * POST /loans/create
 * Validate amount (3000-500000), interest_rate=0.20, co_maker required,
 * KYC complete, no duplicate active loan, status=draft.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, conflict, unprocessable } from "../_shared/errors.ts";
import { loanCreateSchema } from "../_shared/validation.ts";

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

    // Only borrowers can create loans
    if (!hasRole(payload, "borrower")) {
      return forbidden("Only borrowers can create loan applications");
    }

    const body = await req.json();
    const parsed = loanCreateSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { principal, term_days, schedule_type, co_maker, purpose } = parsed.data;
    const supabase = getServiceClient();

    // 1. Verify borrower exists and KYC is complete
    const { data: borrower, error: borrowerError } = await supabase
      .from("borrowers")
      .select("id, kyc_status")
      .eq("user_id", payload.sub)
      .is("deleted_at", null)
      .single();

    if (borrowerError || !borrower) {
      return forbidden("Borrower profile not found");
    }

    const KYC_COMPLETE_STATUSES = ["verified", "phone_verified", "docs_uploaded"];
    if (!KYC_COMPLETE_STATUSES.includes(borrower.kyc_status) && borrower.kyc_status !== "verified") {
      return unprocessable(
        "KYC verification is required before applying for a loan",
        { kyc_status: borrower.kyc_status }
      );
    }

    // 2. Check for duplicate active loans
    const ACTIVE_STATUSES = ["draft", "under_review", "approved", "disbursed"];
    const { data: activeLoans, error: activeError } = await supabase
      .from("loans")
      .select("id, status")
      .eq("borrower_id", borrower.id)
      .in("status", ACTIVE_STATUSES)
      .is("deleted_at", null);

    if (activeError) {
      return serverError("Failed to check existing loans");
    }

    if (activeLoans && activeLoans.length > 0) {
      return conflict("You already have an active loan application");
    }

    // 3. Verify documents are uploaded
    const { data: documents, error: docsError } = await supabase
      .from("documents")
      .select("id, document_type, status")
      .eq("borrower_id", borrower.id)
      .in("document_type", ["government_id", "proof_of_billing", "selfie"])
      .is("deleted_at", null);

    if (docsError) {
      return serverError("Failed to check documents");
    }

    const requiredDocTypes = ["government_id", "proof_of_billing", "selfie"];
    const uploadedDocTypes = (documents ?? [])
      .filter((d) => d.status === "verified" || d.status === "pending")
      .map((d) => d.document_type);
    const missingDocs = requiredDocTypes.filter((t) => !uploadedDocTypes.includes(t));

    if (missingDocs.length > 0) {
      return unprocessable(
        "Required documents are missing",
        { missing_documents: missingDocs }
      );
    }

    // 4. Create co_maker record
    const { data: coMaker, error: coMakerError } = await supabase
      .from("co_makers")
      .insert({
        full_name: co_maker.full_name,
        phone: co_maker.phone,
        address: co_maker.address,
        relationship: co_maker.relationship,
        consent_at: new Date().toISOString(),
      })
      .select("id")
      .single();

    if (coMakerError || !coMaker) {
      return serverError("Failed to create co-maker record");
    }

    // 5. Create the loan
    const interest_rate = 0.20;
    const total_payable = principal * (1 + interest_rate);

    const { data: loan, error: loanError } = await supabase
      .from("loans")
      .insert({
        borrower_id: borrower.id,
        co_maker_id: coMaker.id,
        principal,
        interest_rate,
        term_days,
        schedule_type,
        status: "draft",
        purpose,
      })
      .select("id, principal, interest_rate, total_payable, term_days, schedule_type, status, created_at")
      .single();

    if (loanError || !loan) {
      // Cleanup co_maker on failure
      await supabase.from("co_makers").delete().eq("id", coMaker.id);
      return serverError("Failed to create loan application");
    }

    // 6. Link co_maker to loan via junction table
    await supabase.from("loan_co_makers").insert({
      loan_id: loan.id,
      co_maker_id: coMaker.id,
    });

    // 7. Audit log
    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "loan_created",
      new_value: { loan_id: loan.id, principal, term_days, schedule_type },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        loan,
        co_maker: { id: coMaker.id, full_name: co_maker.full_name },
        breakdown: {
          principal,
          interest_rate,
          interest_amount: principal * interest_rate,
          total_payable,
        },
      },
      201,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Loan create error:", err);
    return serverError("Failed to create loan application");
  }
});
