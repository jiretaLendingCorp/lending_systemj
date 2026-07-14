/**
 * POST /auth/otp-verify
 * Verify OTP, mark email verified, invalidate after 3 failed attempts.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, unauthorized, conflict } from "../_shared/errors.ts";
import { otpVerifySchema } from "../_shared/validation.ts";

const MAX_OTP_ATTEMPTS = 3;

async function hashOtp(code: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(code);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    const { payload } = await authenticateRequest(req);
    const body = await req.json();
    const parsed = otpVerifySchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { phone, code } = parsed.data;
    const supabase = getServiceClient();

    // Find the most recent unused OTP for this user
    const { data: otpRecords, error: fetchError } = await supabase
      .from("otp_codes")
      .select("*")
      .eq("user_id", payload.sub)
      .eq("is_used", false)
      .order("created_at", { ascending: false })
      .limit(1);

    if (fetchError) {
      return serverError("Failed to fetch OTP");
    }

    if (!otpRecords || otpRecords.length === 0) {
      return unauthorized("No valid OTP found. Please request a new one.");
    }

    const otpRecord = otpRecords[0];

    // Check if OTP has expired
    if (new Date(otpRecord.expires_at) < new Date()) {
      // Mark as used so it can't be retried
      await supabase
        .from("otp_codes")
        .update({ is_used: true })
        .eq("id", otpRecord.id);

      return unauthorized("OTP has expired. Please request a new one.");
    }

    // Check if max attempts exceeded
    if (otpRecord.attempts >= MAX_OTP_ATTEMPTS) {
      await supabase
        .from("otp_codes")
        .update({ is_used: true })
        .eq("id", otpRecord.id);

      return conflict(
        `Maximum verification attempts (${MAX_OTP_ATTEMPTS}) exceeded. Please request a new OTP.`
      );
    }

    // Verify the code
    const inputHash = await hashOtp(code);
    if (inputHash !== otpRecord.code_hash) {
      // Increment attempt counter
      await supabase
        .from("otp_codes")
        .update({ attempts: otpRecord.attempts + 1 })
        .eq("id", otpRecord.id);

      const remaining = MAX_OTP_ATTEMPTS - (otpRecord.attempts + 1);
      return unauthorized(
        `Invalid OTP. ${remaining} attempt${remaining !== 1 ? "s" : ""} remaining.`
      );
    }

    // OTP is valid — mark as used
    await supabase
      .from("otp_codes")
      .update({ is_used: true })
      .eq("id", otpRecord.id);

    // Update user's phone and mark as verified
    const { error: updateError } = await supabase.auth.admin.updateUserById(payload.sub, {
      phone: phone,
      phone_confirm: true,
    });

    if (updateError) {
      console.error("Failed to update user phone verification:", updateError);
      return serverError("Failed to verify phone number");
    }

    // Update borrower record if exists
    await supabase
      .from("borrowers")
      .update({ kyc_status: "phone_verified" })
      .eq("user_id", payload.sub)
      .is("deleted_at", null);

    // Log audit event
    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "otp_verified",
      new_value: { phone },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      { message: "Phone number verified successfully", phone },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("OTP verify error:", err);
    return serverError("Failed to verify OTP");
  }
});
