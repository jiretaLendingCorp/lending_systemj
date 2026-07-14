// supabase/functions/payments/create/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, conflict, unprocessable } from "../_shared/errors.ts";
import { paymentCreateSchema } from "../_shared/validation.ts";

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

    const body = await req.json();
    const parsed = paymentCreateSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { loan_id, amount, method, reference_number, idempotency_key } = parsed.data;
    const supabase = getServiceClient();

    const { data: existingKey } = await supabase
      .from("idempotency_keys")
      .select("response_body")
      .eq("key", idempotency_key)
      .maybeSingle();

    if (existingKey) {
      return new Response(JSON.stringify(existingKey.response_body), {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders(req) },
      });
    }

    const { data: loan, error: loanError } = await supabase
      .from("loans")
      .select("id, lender_id, principal, total_payable, penalty_amount, final_balance, status, due_at")
      .eq("id", loan_id)
      .is("deleted_at", null)
      .single();

    if (loanError || !loan) {
      return badRequest("Loan not found");
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

    if (!["disbursed", "defaulted"].includes(loan.status)) {
      return unprocessable(
        `Cannot make payment on loan with status '${loan.status}'`
      );
    }

    const totalPayable = Number(loan.final_balance ?? loan.total_payable);
    const penaltyAmount = Number(loan.penalty_amount ?? 0);

    const { data: existingPayments } = await supabase
      .from("payments")
      .select("amount, status")
      .eq("loan_id", loan_id)
      .eq("status", "completed");

    const totalPaid = (existingPayments ?? []).reduce(
      (sum: number, p: { amount: number }) => sum + Number(p.amount),
      0
    );

    const remainingBalance = totalPayable - totalPaid;

    if (amount > remainingBalance) {
      return badRequest(
        `Payment amount exceeds remaining balance of ₱${remainingBalance.toLocaleString()}`,
        { remaining_balance: remainingBalance }
      );
    }

    if (amount <= 0) {
      return badRequest("Payment amount must be greater than zero");
    }

    const { data: payment, error: paymentError } = await supabase
      .from("payments")
      .insert({
        loan_id,
        lender_id: loan.lender_id,
        amount,
        method,
        status: method === "gcash" ? "pending" : "completed",
        reference_number: reference_number ?? null,
        idempotency_key,
        collected_by: method !== "gcash" ? payload.sub : null,
        collected_at: method !== "gcash" ? new Date().toISOString() : null,
      })
      .select("id, amount, method, status, reference_number, created_at")
      .single();

    if (paymentError) {
      if (paymentError.code === "23505") {
        return conflict("Duplicate payment request");
      }
      return serverError("Failed to create payment");
    }

    if (method === "gcash") {
      const xenditApiKey = Deno.env.get("XENDIT_SECRET_KEY");
      if (xenditApiKey) {
        try {
          const xenditResponse = await fetch("https://api.xendit.co/v2/invoices", {
            method: "POST",
            headers: {
              Authorization: `Basic ${btoa(xenditApiKey + ":")}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              external_id: payment.id,
              amount,
              description: `Loan payment - $loan_id`,
              payment_methods: ["GCASH"],
              success_redirect_url: `${Deno.env.get("FRONTEND_URL")}/payment/success`,
              failure_redirect_url: `${Deno.env.get("FRONTEND_URL")}/payment/failed`,
            }),
          });

          const xenditData = await xenditResponse.json();
          await supabase
            .from("payments")
            .update({ xendit_payment_id: xenditData.id })
            .eq("id", payment.id);
        } catch (xenditErr) {
          console.error("Xendit invoice creation failed:", xenditErr);
        }
      }
    }

    const newTotalPaid = totalPaid + amount;
    if (newTotalPaid >= totalPayable) {
      await supabase
        .from("loans")
        .update({ status: "paid", updated_at: new Date().toISOString() })
        .eq("id", loan_id);
    }

    const responseBody = { data: payment };
    await supabase.from("idempotency_keys").insert({
      key: idempotency_key,
      response_body: responseBody,
      expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24h TTL
    });

    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "payment_created",
      new_value: { payment_id: payment.id, loan_id, amount, method },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    const { data: lender } = await supabase
      .from('lenders')
      .select("user_id")
      .eq("id", loan.lender_id)
      .single();

    if (lender) {
      await supabase.from("notifications").insert({
        user_id: lender.user_id,
        type: "payment_received",
        title: "Payment Received",
        body: `Your payment of ₱${amount.toLocaleString()} via $method has been recorded.`,
      });
    }

    return successResponse(responseBody, 201, corsHeaders(req));
  } catch (err) {
    console.error("Payment create error:", err);
    return serverError("Failed to create payment");
  }
});
