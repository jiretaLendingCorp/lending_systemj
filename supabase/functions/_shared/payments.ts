// supabase/functions/_shared/payments.ts
import { getServiceClient } from "./supabase.ts";

export interface PaymentContext {
  paymentId: string;
  loanId: string;
  lenderId: string;
  amount: number;
  method: "gcash" | "office" | "cash";
  idempotencyKey?: string;
}

export interface PaymentResult {
  success: boolean;
  status: "pending" | "completed" | "failed" | "refunded";
  referenceNumber?: string;
  error?: string;
}

export async function processPayment(ctx: PaymentContext): Promise<PaymentResult> {
  const supabase = getServiceClient();

  if (ctx.idempotencyKey) {
    const { data: existing } = await supabase
      .from("idempotency_keys")
      .select("response_body, status_code")
      .eq("key", ctx.idempotencyKey)
      .maybeSingle();

    if (existing?.response_body) {
      return existing.response_body as PaymentResult;
    }
  }

  const { data: loan, error: loanError } = await supabase
    .from("loans")
    .select("id, status, total_payable, penalty_amount, final_balance")
    .eq("id", ctx.loanId)
    .is("deleted_at", null)
    .single();

  if (loanError || !loan) {
    return { success: false, status: "failed", error: "Loan not found" };
  }

  if (!["disbursed", "defaulted"].includes(loan.status)) {
    return { success: false, status: "failed", error: `Loan status ${loan.status} does not allow payments` };
  }

  const { data: totalPaidRow } = await supabase
    .from("payments")
    .select("amount")
    .eq("loan_id", ctx.loanId)
    .eq("status", "completed")
    .is("deleted_at", null);

  const totalPaid = (totalPaidRow ?? []).reduce(
    (sum, p) => sum + Number(p.amount),
    0
  );

  const owed = Number(loan.final_balance ?? 0) ||
    (Number(loan.total_payable) + Number(loan.penalty_amount ?? 0));

  if (ctx.amount > owed - totalPaid + 0.01) {
    return {
      success: false,
      status: "failed",
      error: `Payment exceeds outstanding balance of ${(owed - totalPaid).toFixed(2)}`,
    };
  }

  const referenceNumber = `PMT-${Date.now()}-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;

  const { data: payment, error: insertError } = await supabase
    .from("payments")
    .insert({
      loan_id: ctx.loanId,
      lender_id: ctx.lenderId,
      amount: ctx.amount,
      method: ctx.method,
      status: "completed",
      reference_number: referenceNumber,
      idempotency_key: ctx.idempotencyKey,
      collected_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (insertError) {
    return { success: false, status: "failed", error: insertError.message };
  }

  if (ctx.idempotencyKey) {
    const result: PaymentResult = {
      success: true,
      status: "completed",
      referenceNumber,
    };
    await supabase.from("idempotency_keys").upsert({
      key: ctx.idempotencyKey,
      response_body: result,
      status_code: 200,
      expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    });
  }

  await supabase.from("notifications").insert({
    user_id: (await supabase.from("lenders").select("user_id").eq("id", ctx.lenderId).single()).data?.user_id,
    type: "payment_received",
    title: "Payment Received",
    body: `Your payment of ₱${ctx.amount.toLocaleString()} has been received. Reference: ${referenceNumber}`,
    data: { payment_id: payment.id, loan_id: ctx.loanId, amount: ctx.amount },
  });

  return { success: true, status: "completed", referenceNumber };
}

export function verifyXenditWebhookSignature(
  rawBody: string,
  signature: string,
  webhookToken: string
): boolean {
  if (!webhookToken || !signature) return false;
  return signature === webhookToken;
}
