// supabase/functions/auth/otp-send/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, conflict } from "../_shared/errors.ts";
import { otpSendSchema } from "../_shared/validation.ts";

const OTP_RATE_LIMIT = 3;
const OTP_TTL_MINUTES = 5;
const OTP_LENGTH = 6;

function generateOtp(): string {
  const min = Math.pow(10, OTP_LENGTH - 1);
  const max = Math.pow(10, OTP_LENGTH) - 1;
  return Math.floor(Math.random() * (max - min + 1) + min).toString();
}

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
    const parsed = otpSendSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { phone } = parsed.data;
    const supabase = getServiceClient();

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const { count, error: countError } = await supabase
      .from("otp_codes")
      .select("*", { count: "exact", head: true })
      .eq("user_id", payload.sub)
      .gte("created_at", oneHourAgo);

    if (countError) {
      return serverError("Failed to check rate limit");
    }

    if ((count ?? 0) >= OTP_RATE_LIMIT) {
      return conflict("OTP rate limit exceeded. Maximum 3 requests per hour.");
    }

    const code = generateOtp();
    const codeHash = await hashOtp(code);
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000).toISOString();

    const { error: insertError } = await supabase.from("otp_codes").insert({
      user_id: payload.sub,
      code_hash: codeHash,
      expires_at: expiresAt,
      is_used: false,
      attempts: 0,
    });

    if (insertError) {
      return serverError("Failed to create OTP");
    }

    const smsApiKey = Deno.env.get("SMS_API_KEY");
    const smsProvider = Deno.env.get("SMS_PROVIDER") ?? "semaphore";

    if (smsApiKey) {
      try {
        const semaphoreUrl = "https://api.semaphore.co/api/v4/messages";
        await fetch(semaphoreUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            apikey: smsApiKey,
            number: phone,
            message: `Your Jireta Loan verification code is: $code. Valid for $OTP_TTL_MINUTES minutes. Do not share this code.`,
            sendername: "Jireta Loan",
          }),
        });
      } catch (smsError) {
        console.error("SMS send failed:", smsError);
      }
    }

    const isDev = Deno.env.get("DENO_ENV") === "development";

    return successResponse(
      {
        message: "OTP sent successfully",
        expires_at: expiresAt,
        ...(isDev && { code }),
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("OTP send error:", err);
    return serverError("Failed to send OTP");
  }
});
