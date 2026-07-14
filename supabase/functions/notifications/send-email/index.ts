// supabase/functions/notifications/send-email/index.ts
import { handleCors, corsHeaders } from "../../_shared/cors.ts";
import { authenticateRequest } from "../../_shared/jwt.ts";
import { getServiceClient } from "../../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../../_shared/errors.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const FRONTEND_URL = Deno.env.get("FRONTEND_URL") ?? "http://localhost:3000";
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") ?? "noreply@jireta_loan.ph";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    const cronSecret = req.headers.get("x-cron-secret");
    const isCron = cronSecret === Deno.env.get("CRON_SECRET");

    if (!isCron) {
      const authResult = await authenticateRequest(req);
      if ("error" in authResult) return authResult.error;
    }

    const body = await req.json();
    const { user_id, email_type, email } = body;

    if (!user_id || !email_type || !email) {
      return badRequest("user_id, email_type, and email are required");
    }

    const supabase = getServiceClient();

    const { data: tokenData, error: tokenError } = await supabase.auth.admin.generateLink({
      type: email_type === "email_verification" ? "magiclink" : "recovery",
      email,
    });

    if (tokenError) {
      console.error("Token generation error:", tokenError);
      return serverError("Failed to generate verification token");
    }

    let verificationUrl: string;
    let subject: string;
    let htmlBody: string;

    switch (email_type) {
      case "email_verification": {
        verificationUrl = `${FRONTEND_URL}/auth/verify-email?token=${encodeURIComponent(tokenData.properties?.hashed_token ?? "")}&type=email_verification`;
        subject = "Verify Your Email - Jireta Loan";
        htmlBody = `
          <!DOCTYPE html>
          <html>
          <head><meta charset="utf-8"></head>
          <body style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #1a56db;">Jireta Loan Email Verification</h2>
            <p>Please verify your email address by clicking the link below:</p>
            <a href="${verificationUrl}" style="display: inline-block; padding: 12px 24px; background-color: #1a56db; color: white; text-decoration: none; border-radius: 6px;">
              Verify Email
            </a>
            <p style="color: #6b7280; font-size: 14px; margin-top: 20px;">
              This link expires in 24 hours. If you didn't create an account, please ignore this email.
            </p>
          </body>
          </html>
        `;
        break;
      }

      case "password_reset": {
        verificationUrl = `${FRONTEND_URL}/auth/reset-password?token=${encodeURIComponent(tokenData.properties?.hashed_token ?? "")}&type=recovery`;
        subject = "Reset Your Password - Jireta Loan";
        htmlBody = `
          <!DOCTYPE html>
          <html>
          <head><meta charset="utf-8"></head>
          <body style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #1a56db;">Jireta Loan Password Reset</h2>
            <p>You requested a password reset. Click below to set a new password:</p>
            <a href="${verificationUrl}" style="display: inline-block; padding: 12px 24px; background-color: #1a56db; color: white; text-decoration: none; border-radius: 6px;">
              Reset Password
            </a>
            <p style="color: #6b7280; font-size: 14px; margin-top: 20px;">
              This link expires in 1 hour. If you didn't request this, please ignore this email.
            </p>
          </body>
          </html>
        `;
        break;
      }

      case "loan_status": {
        const { loan_status, loan_amount } = body;
        const formattedAmount = Number(loan_amount ?? 0).toLocaleString();
        subject = `Loan ${loan_status === "approved" ? "Approved" : "Update"} - Jireta Loan`;
        htmlBody = `
          <!DOCTYPE html>
          <html>
          <head><meta charset="utf-8"></head>
          <body style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #1a56db;">Jireta Loan Loan Update</h2>
            <p>Your loan application for ₱${formattedAmount} has been <strong>${loan_status}</strong>.</p>
            <p>Log in to your Jireta Loan account for more details.</p>
          </body>
          </html>
        `;
        break;
      }

      default:
        return badRequest(`Unknown email type: ${email_type}`);
    }

    if (RESEND_API_KEY) {
      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: FROM_EMAIL,
          to: email,
          subject,
          html: htmlBody,
        }),
      });

      if (!response.ok) {
        const errorBody = await response.text();
        console.error("Resend API error:", errorBody);
        return serverError("Failed to send email");
      }
    }

    await supabase.from("audit_logs").insert({
      user_id: user_id,
      user_role: "system",
      action: `email_sent_${email_type}`,
      new_value: { email_type, email },
    });

    return successResponse(
      { message: "Email sent successfully", email_type },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Send email error:", err);
    return serverError("Failed to send email");
  }
});
