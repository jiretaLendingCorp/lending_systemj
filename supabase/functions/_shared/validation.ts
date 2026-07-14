// supabase/functions/_shared/validation.ts
import { z } from "https://esm.sh/zod@3.22.4";


export const otpSendSchema = z.object({
  phone: z
    .string()
    .regex(/^(\+63|0)9\d{9}$/, "Invalid Philippine phone number"),
});

export const otpVerifySchema = z.object({
  phone: z
    .string()
    .regex(/^(\+63|0)9\d{9}$/, "Invalid Philippine phone number"),
  code: z.string().length(6, "OTP must be 6 digits"),
});

export const googleCallbackSchema = z.object({
  code: z.string().min(1, "Authorization code is required"),
  state: z.string().optional(),
});


export const loanCreateSchema = z
  .object({
    principal: z
      .number()
      .min(3000, "Minimum loan amount is ₱3,000")
      .max(500000, "Maximum loan amount is ₱500,000"),
    term_days: z
      .number()
      .int()
      .min(7, "Minimum term is 7 days")
      .max(365, "Maximum term is 365 days"),
    schedule_type: z.enum(["daily", "weekly", "monthly"]),
    co_maker: z.object({
      full_name: z.string().min(2, "Co-maker name is required"),
      phone: z
        .string()
        .regex(/^(\+63|0)9\d{9}$/, "Invalid Philippine phone number"),
      address: z.string().min(5, "Co-maker address is required"),
      relationship: z.string().min(1, "Relationship is required"),
    }),
    purpose: z.string().min(1, "Loan purpose is required").max(500),
  })
  .strict();

export const loanApproveSchema = z.object({
  note: z.string().max(500).optional(),
});

export const loanRejectSchema = z.object({
  reason: z.string().min(5, "Rejection reason is required").max(1000),
});


export const paymentCreateSchema = z.object({
  loan_id: z.string().uuid("Invalid loan ID"),
  amount: z.number().positive("Amount must be positive"),
  method: z.enum(["gcash", "office", "cash"]),
  reference_number: z.string().optional(),
  idempotency_key: z.string().min(1, "Idempotency key is required"),
});


export const gpsCheckinSchema = z.object({
  task_id: z.string().uuid("Invalid task ID"),
  task_type: z.enum(["disbursement", "collection"]),
  latitude: z
    .number()
    .min(-90, "Invalid latitude")
    .max(90, "Invalid latitude"),
  longitude: z
    .number()
    .min(-180, "Invalid longitude")
    .max(180, "Invalid longitude"),
  accuracy: z.number().positive().optional(),
});


export const assignRiderSchema = z.object({
  rider_id: z.string().uuid("Invalid rider ID"),
});


export const markDeliveredSchema = z.object({
  latitude: z
    .number()
    .min(-90, "Invalid latitude")
    .max(90, "Invalid latitude"),
  longitude: z
    .number()
    .min(-180, "Invalid longitude")
    .max(180, "Invalid longitude"),
  receipt_url: z.string().url("Invalid receipt URL").optional(),
});


export const markCollectedSchema = z.object({
  latitude: z
    .number()
    .min(-90, "Invalid latitude")
    .max(90, "Invalid latitude"),
  longitude: z
    .number()
    .min(-180, "Invalid longitude")
    .max(180, "Invalid longitude"),
  photo_receipt_url: z.string().url("Invalid photo URL"),
  amount: z.number().positive("Amount must be positive"),
  method: z.enum(["gcash", "office", "cash"]),
});


export const settingsUpdateSchema = z.object({
  interest_rate: z.number().min(0).max(1).optional(),
  penalty_rate: z.number().min(0).max(1).optional(),
  penalty_threshold_days: z.number().int().min(1).optional(),
  sms_templates: z.record(z.string()).optional(),
  notification_preferences: z.record(z.boolean()).optional(),
  system_flags: z.record(z.unknown()).optional(),
});


export const loanListQuerySchema = z.object({
  status: z
    .enum(["draft", "under_review", "approved", "disbursed", "paid", "defaulted", "rejected"])
    .optional(),
  page: z.coerce.number().int().min(1).default(1),
  page_size: z.coerce.number().int().min(1).max(100).default(20),
  sort_by: z.enum(["created_at", "principal", "status"]).default("created_at"),
  sort_order: z.enum(["asc", "desc"]).default("desc"),
});

export const paymentListQuerySchema = z.object({
  loan_id: z.string().uuid().optional(),
  status: z.enum(["pending", "completed", "failed", "refunded"]).optional(),
  page: z.coerce.number().int().min(1).default(1),
  page_size: z.coerce.number().int().min(1).max(100).default(20),
});


export const xenditWebhookSchema = z.object({
  id: z.string(),
  external_id: z.string(),
  status: z.string(),
  amount: z.number(),
  payment_method: z.string().optional(),
  created: z.string().optional(),
  updated: z.string().optional(),
});

export const smsStatusWebhookSchema = z.object({
  message_id: z.string(),
  status: z.enum(["delivered", "failed", "undelivered", "queued", "sent"]),
  error_code: z.string().optional(),
  timestamp: z.string().optional(),
});
