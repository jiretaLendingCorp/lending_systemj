// supabase/functions/loans/preview/index.ts
import { handleCors, corsHeaders } from "../../_shared/cors.ts";
import { authenticateRequest } from "../../_shared/jwt.ts";
import { badRequest, successResponse, serverError } from "../../_shared/errors.ts";
import { loanCreateSchema } from "../../_shared/validation.ts";
import { computeLoan, validateLoanTerms } from "../../_shared/loan-finance.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    const authResult = await authenticateRequest(req);
    if ("error" in authResult) return authResult.error;

    const body = await req.json();
    const parsed = loanCreateSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { principal, term_days, schedule_type } = parsed.data;

    const terms = {
      principal,
      interestRate: 0.20,
      termDays: term_days,
      scheduleType: schedule_type as "daily" | "weekly" | "monthly",
    };

    const validationError = validateLoanTerms(terms);
    if (validationError) {
      return badRequest(validationError);
    }

    const computed = computeLoan(terms);

    return successResponse(
      {
        preview: {
          principal: computed.principal,
          interest_rate: computed.interestRate,
          interest_amount: computed.interestAmount,
          total_payable: computed.totalPayable,
          installment_count: computed.installmentCount,
          amount_per_installment: computed.amountPerInstallment,
          schedule_type: computed.scheduleType,
          term_days: computed.termDays,
          due_at: computed.dueAt,
          schedule: computed.schedule,
        },
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Loan preview error:", err);
    return serverError("Failed to compute loan preview");
  }
});
