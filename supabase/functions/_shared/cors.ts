// supabase/functions/_shared/cors.ts
const DEFAULT_ALLOWED_ORIGINS: string[] = [
  "http://localhost:3000",
  "http://localhost:8080",
  "http://localhost:5000",
  "http://localhost:5500",
  "http://127.0.0.1:3000",
  "http://127.0.0.1:8080",
  "http://127.0.0.1:5000",
  "http://127.0.0.1:5500",
  "https://lcelzrvpqwlbeccrwpkp.supabase.co",
  "https://preview-jireta-loan.space-z.ai",
  "https://jireta-loan.space-z.ai",
];

const ALLOWED_ORIGINS: string[] = [
  ...DEFAULT_ALLOWED_ORIGINS,
  Deno.env.get("CORS_ORIGIN") ?? "",
  Deno.env.get("CORS_ORIGIN_ALT") ?? "",
  Deno.env.get("SITE_URL") ?? "",
].filter(Boolean);

export const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-idempotency-key, x-request-id, accept",
  "Access-Control-Max-Age": "86400",
  "Access-Control-Allow-Credentials": "true",
};

export function getAllowedOrigin(req: Request): string | null {
  const origin = req.headers.get("Origin");
  if (!origin) {
    return ALLOWED_ORIGINS[0] ?? "*";
  }
  if (ALLOWED_ORIGINS.includes(origin)) {
    return origin;
  }
  try {
    const url = new URL(origin);
    if (
      url.hostname === "localhost" ||
      url.hostname === "127.0.0.1" ||
      url.hostname.endsWith(".space-z.ai") ||
      url.hostname.endsWith(".supabase.co")
    ) {
      return origin;
    }
  } catch (_) {
  }
  return null;
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
    return new Response(null, {
      status: 204,
      headers: corsHeaders(req),
    });
  }
  return null;
}

export function withCors(req: Request, body: BodyInit, init?: ResponseInit): Response {
  return new Response(body, {
    ...init,
    headers: {
      ...corsHeaders(req),
      ...(init?.headers ?? {}),
    },
  });
}
