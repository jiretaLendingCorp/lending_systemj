// supabase/functions/auth/google-callback/index.ts
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError } from "../_shared/errors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const FRONTEND_URL = Deno.env.get("FRONTEND_URL") ?? "http://localhost:3000";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const url = new URL(req.url);
    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");
    const error = url.searchParams.get("error");

    if (error) {
      return Response.redirect(
        `$FRONTEND_URL/auth/error?message=${encodeURIComponent(error)}`
      );
    }

    if (!code) {
      return Response.redirect(
        `$FRONTEND_URL/auth/error?message=${encodeURIComponent("Missing authorization code")}`
      );
    }

    const supabase = getServiceClient();

    const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(code);

    if (exchangeError || !data.user) {
      console.error("OAuth code exchange failed:", exchangeError);
      return Response.redirect(
        `$FRONTEND_URL/auth/error?message=${encodeURIComponent("Authentication failed")}`
      );
    }

    const user = data.user;

    const { data: existingBorrower } = await supabase
      .from('lenders')
      .select("id")
      .eq("user_id", user.id)
      .is("deleted_at", null)
      .maybeSingle();

    if (!existingBorrower) {
      const fullName =
        user.user_metadata?.full_name ??
        user.user_metadata?.name ??
        "";

      await supabase.from('lenders').insert({
        user_id: user.id,
        full_name: fullName,
        kyc_status: "pending",
      });
    }

    await supabase.from("audit_logs").insert({
      user_id: user.id,
      user_role: user.app_metadata?.role ?? "lender",
      action: "google_oauth_login",
      new_value: { provider: "google", email: user.email },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    await supabase
      .from("users")
      .update({ last_login_at: new Date().toISOString() })
      .eq("id", user.id);

    const redirectUrl = state
      ? `$FRONTEND_URL/auth/callback?access_token=${data.session.access_token}&refresh_token=${data.session.refresh_token}&state=$state`
      : `$FRONTEND_URL/auth/callback?access_token=${data.session.access_token}&refresh_token=${data.session.refresh_token}`;

    return Response.redirect(redirectUrl);
  } catch (err) {
    console.error("Google callback error:", err);
    return Response.redirect(
      `$FRONTEND_URL/auth/error?message=${encodeURIComponent("Internal server error")}`
    );
  }
});
