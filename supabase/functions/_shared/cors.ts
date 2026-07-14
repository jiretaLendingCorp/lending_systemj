/**
 * CORS headers for LendFlow Edge Functions.
 * Only whitelisted origins are allowed.
 */

const ALLOWED_ORIGINS: string[] = [
  Deno.env.get("CORS_ORIGIN") ?? "http://localhost:3000",
  Deno.env.get("CORS_ORIGIN_ALT") ?? "",
].filter(Boolean);

export const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-idempotency-key, x-request-id",
  "Access-Control-Max-Age": "86400",
};

export function getAllowedOrigin(req: Request): string | null {
  const origin = req.headers.get("Origin");
  if (!origin) return null;
  return ALLOWED_ORIGINS.includes(origin) ? origin : null;
}

export function corsHeaders(req: Request): Record<string, string> {
  const origin = getAllowedOrigin(req);
  return {
    ...CORS_HEADERS,
    "Access-Control-Allow-Origin": origin ?? "",
  };
}

export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(req) });
  }
  return null;
}
