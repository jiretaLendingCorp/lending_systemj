// supabase/functions/loans/create/index.ts
import { handleCors, corsHeaders } from "../../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../../_shared/jwt.ts";
import { getServiceClient } from "../../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, conflict, unprocessable } from "../../_shared/errors.ts";
import { loanCreateSchema } from "../../_shared/validation.ts";
import { computeLoan } from "../../_shared/loan-finance.ts";

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

    if (!hasRole(payload, "lender")) {
      return forbidden("Only lenders can create loan applications");
    }

    const body = await req.json();
    const parsed = loanCreateSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { principal, term_days, schedule_type, co_maker, purpose } = parsed.data;
    const supabase = getServiceClient();

    const { data: lender, error: borrowerError } = await supabase
      .from('lenders')
      .select("id, kyc_status")
      .eq("user_id", payload.sub)
      .is("deleted_at", null)
      .single();

    if (borrowerError || !lender) {
      return forbidden("Lender profile not found");
    }

    const KYC_COMPLETE_STATUSES = ["verified", "phone_verified", "docs_uploaded"];
    if (!KYC_COMPLETE_STATUSES.includes(lender.kyc_status) && lender.kyc_status !== "verified") {
      return unprocessable(
        "KYC verification is required before applying for a loan",
        { kyc_status: lender.kyc_status }
      );
    }

    const ACTIVE_STATUSES = ["draft", "under_review", "approved", "disbursed"];
    const { data: activeLoans, error: activeError } = await supabase
      .from("loans")
      .select("id, status")
      .eq("lender_id", lender.id)
      .in("status", ACTIVE_STATUSES)
      .is("deleted_at", null);

    if (activeError) {
      return serverError("Failed to check existing loans");
    }

    if (activeLoans && activeLoans.length > 0) {
      return conflict("You already have an active loan application");
    }

    const { data: documents, error: docsError } = await supabase
      .from("documents")
      .select("id, document_type, status")
      .eq("lender_id", lender.id)
      .in("document_type", ["government_id", "proof_of_billing", "selfie"])
      .is("deleted_at", null);

    if (docsError) {
      return serverError("Failed to check documents");
    }

    const requiredDocTypes = ["government_id", "proof_of_billing", "selfie"];
    const uploadedDocTypes = (documents ?? [])
      .filter((d: { status: string; document_type: string }) => d.status === "verified" || d.status === "pending")
      .map((d: { document_type: string }) => d.document_type);
    const missingDocs = requiredDocTypes.filter((t) => !uploadedDocTypes.includes(t));

    if (missingDocs.length > 0) {
      return unprocessable(
        "Required documents are missing",
        { missing_documents: missingDocs }
      );
    }

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

    const interest_rate = 0.20;
    const computed = computeLoan({
      principal,
      interestRate: interest_rate,
      termDays: term_days,
      scheduleType: schedule_type,
    });
    const total_payable = computed.totalPayable;

    const { data: loan, error: loanError } = await supabase
      .from("loans")
      .insert({
        lender_id: lender.id,
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
      await supabase.from("co_makers").delete().eq("id", coMaker.id);
      return serverError("Failed to create loan application");
    }

    await supabase.from("loan_co_makers").insert({
      loan_id: loan.id,
      co_maker_id: coMaker.id,
    });

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
