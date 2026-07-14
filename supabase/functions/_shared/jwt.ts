/**
 * JWT verification and role extraction for LendFlow Edge Functions.
 * Uses Supabase Auth JWT verification with JWKS.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  app_metadata?: {
    role?: string;
  };
  [key: string]: unknown;
}

export type UserRole = "borrower" | "rider" | "manager" | "admin";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const JWT_SECRET = Deno.env.get("JWT_SECRET") ?? "";

/**
 * Verify a JWT token from the Authorization header.
 * Returns the decoded payload or null if invalid.
 */
export async function verifyJwt(authHeader: string | null): Promise<JwtPayload | null> {
  if (!authHeader) return null;

  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) return null;

  try {
    // Use Supabase Auth admin API to get user from token
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: { Authorization: `Bearer ${token}` },
      },
    });

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) return null;

    const user = data.user;
    const role: UserRole = (user.app_metadata?.role as UserRole) ?? "borrower";

    return {
      sub: user.id,
      email: user.email ?? "",
      role,
      app_metadata: user.app_metadata,
    };
  } catch {
    return null;
  }
}

/**
 * Check if a user has one of the required roles.
 */
export function hasRole(payload: JwtPayload, ...roles: UserRole[]): boolean {
  return roles.includes(payload.role as UserRole);
}

/**
 * Require that the JWT payload has one of the given roles.
 * Returns the role if valid, or null if unauthorized.
 */
export function requireRole(payload: JwtPayload, ...roles: UserRole[]): UserRole | null {
  if (hasRole(payload, ...roles)) {
    return payload.role as UserRole;
  }
  return null;
}

/**
 * Extract and verify JWT from request, returning payload or error response.
 */
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
