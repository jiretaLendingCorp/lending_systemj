// supabase/functions/_shared/jwt.ts
import { createClient } from "supabase";

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  app_metadata?: {
    role?: string;
  };
  [key: string]: unknown;
}

export type UserRole = "lender" | "rider" | "employee" | "head_manager";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const JWT_SECRET = Deno.env.get("JWT_SECRET") ?? "";

export async function verifyJwt(authHeader: string | null): Promise<JwtPayload | null> {
  if (!authHeader) return null;

  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) return null;

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: { Authorization: `Bearer ${token}` },
      },
    });

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) return null;

    const user = data.user;
    const role: UserRole = (user.app_metadata?.role as UserRole) ?? "lender";

    return {
      sub: user.id,
      email: user.email ?? "",
      role,
      app_metadata: user.app_metadata as { role?: string } | undefined,
    };
  } catch {
    return null;
  }
}

export function hasRole(payload: JwtPayload, ...roles: UserRole[]): boolean {
  return roles.includes(payload.role as UserRole);
}

export function requireRole(payload: JwtPayload, ...roles: UserRole[]): UserRole | null {
  if (hasRole(payload, ...roles)) {
    return payload.role as UserRole;
  }
  return null;
}

export async function authenticateRequest(
  req: Request
): Promise<{ payload: JwtPayload } | { error: Response }> {
  const authHeader = req.headers.get("Authorization");
  const payload = await verifyJwt(authHeader);

  if (!payload) {
    return {
      error: new Response(
        JSON.stringify({ error: "Unauthorized", message: "Invalid or missing authentication token" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      ),
    };
  }

  return { payload };
}
