// supabase/functions/_shared/loan-finance.ts
export interface LoanTerms {
  principal: number;
  interestRate: number;
  termDays: number;
  scheduleType: "daily" | "weekly" | "monthly";
}

export interface ComputedLoan extends LoanTerms {
  totalPayable: number;
  interestAmount: number;
  installmentCount: number;
  amountPerInstallment: number;
  dueAt: string;
  schedule: Array<{
    installmentNumber: number;
    amountDue: number;
    dueDate: string;
  }>;
}

export const MIN_PRINCIPAL = 3000;
export const MAX_PRINCIPAL = 500000;
export const MIN_TERM_DAYS = 7;
export const MAX_TERM_DAYS = 365;
export const DEFAULT_INTEREST_RATE = 0.2;
export const DEFAULT_PENALTY_RATE = 0.2;
export const PENALTY_THRESHOLD_DAYS = 30;

export function validateLoanTerms(terms: LoanTerms): string | null {
  if (!Number.isFinite(terms.principal) || terms.principal < MIN_PRINCIPAL) {
    return `Principal must be at least ${MIN_PRINCIPAL}`;
  }
  if (terms.principal > MAX_PRINCIPAL) {
    return `Principal must not exceed ${MAX_PRINCIPAL}`;
  }
  if (terms.interestRate !== DEFAULT_INTEREST_RATE) {
    return `Interest rate must be exactly ${DEFAULT_INTEREST_RATE} (20%)`;
  }
  if (terms.termDays < MIN_TERM_DAYS || terms.termDays > MAX_TERM_DAYS) {
    return `Term days must be between ${MIN_TERM_DAYS} and ${MAX_TERM_DAYS}`;
  }
  if (!["daily", "weekly", "monthly"].includes(terms.scheduleType)) {
    return "Invalid schedule type";
  }
  return null;
}

export function computeLoan(terms: LoanTerms, startDate: Date = new Date()): ComputedLoan {
  const validationError = validateLoanTerms(terms);
  if (validationError) {
    throw new Error(validationError);
  }

  const interestAmount = round2(terms.principal * terms.interestRate);
  const totalPayable = round2(terms.principal + interestAmount);

  let installmentCount: number;
  let intervalDays: number;

  switch (terms.scheduleType) {
    case "daily":
      installmentCount = terms.termDays;
      intervalDays = 1;
      break;
    case "weekly":
      installmentCount = Math.max(1, Math.floor(terms.termDays / 7));
      intervalDays = 7;
      break;
    case "monthly":
      installmentCount = Math.max(1, Math.floor(terms.termDays / 30));
      intervalDays = 30;
      break;
  }

  const baseAmount = round2(totalPayable / installmentCount);
  const schedule: ComputedLoan["schedule"] = [];

  let cursor = new Date(startDate);
  for (let i = 1; i <= installmentCount; i++) {
    cursor = new Date(cursor.getTime() + intervalDays * 24 * 60 * 60 * 1000);
    const amountDue = i === installmentCount
      ? round2(totalPayable - baseAmount * (i - 1))
      : baseAmount;
    schedule.push({
      installmentNumber: i,
      amountDue,
      dueDate: cursor.toISOString().split("T")[0],
    });
  }

  const dueAt = new Date(
    cursor.getTime() + 1 * 24 * 60 * 60 * 1000
  ).toISOString();

  return {
    ...terms,
    totalPayable,
    interestAmount,
    installmentCount,
    amountPerInstallment: baseAmount,
    dueAt,
    schedule,
  };
}

export function computeOutstandingBalance(params: {
  totalPayable: number;
  penaltyAmount: number;
  totalPaid: number;
}): number {
  const owed = params.totalPayable + (params.penaltyAmount ?? 0);
  return round2(Math.max(0, owed - params.totalPaid));
}

export function computePenalty(params: {
  principal: number;
  penaltyRate: number;
  daysOverdue: number;
  thresholdDays: number;
}): number {
  if (params.daysOverdue <= params.thresholdDays) return 0;
  const effectiveDays = params.daysOverdue - params.thresholdDays;
  return round2((params.principal * params.penaltyRate * effectiveDays) / 30);
}

export function computeCollectionEfficiency(params: {
  totalDue: number;
  totalCollected: number;
}): number {
  if (params.totalDue <= 0) return 0;
  return round2((params.totalCollected / params.totalDue) * 100);
}

export function computeAnnualizedInterestRate(monthlyRate: number): number {
  return round2(Math.pow(1 + monthlyRate, 12) - 1);
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
