// supabase/functions/users/me/index.ts
import { corsHeaders, handleCors } from "../../_shared/cors.ts";
import { authenticateRequest } from "../../_shared/jwt.ts";
import { getServiceClient } from "../../_shared/supabase.ts";

interface ProfileRow {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  role: string;
  phone: string | null;
  kyc_status: string;
  employee_id: string | null;
  rider_id: string | null;
  lender_id: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

async function loadProfile(userId: string): Promise<ProfileRow | null> {
  const supabase = getServiceClient();
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .maybeSingle();

  if (error) {
    console.error("loadProfile error", error);
    return null;
  }
  return data as ProfileRow | null;
}

async function loadRoleProfile(
  role: string,
  refId: string
): Promise<Record<string, unknown> | null> {
  const supabase = getServiceClient();
  const table =
    role === "lender"
      ? "lenders"
      : role === "rider"
      ? "riders"
      : role === "employee"
      ? "employees"
      : null;

  if (!table) return null;

  const { data, error } = await supabase
    .from(table)
    .select("*")
    .eq("id", refId)
    .maybeSingle();

  if (error) {
    console.error(`loadRoleProfile(${table}) error`, error);
    return null;
  }
  return data;
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "GET" && req.method !== "PATCH") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders(req), "Content-Type": "application/json" },
    });
  }

  const auth = await authenticateRequest(req);
  if ("error" in auth) return auth.error;

  const payload = auth.payload;
  const supabase = getServiceClient();

  const profile = await loadProfile(payload.sub);

  if (req.method === "GET") {
    let roleProfile: Record<string, unknown> | null = null;
    if (profile?.lender_id) {
      roleProfile = await loadRoleProfile("lender", profile.lender_id);
    } else if (profile?.rider_id) {
      roleProfile = await loadRoleProfile("rider", profile.rider_id);
    } else if (profile?.employee_id) {
      roleProfile = await loadRoleProfile("employee", profile.employee_id);
    }

    const response = {
      id: payload.sub,
      email: payload.email,
      role: payload.role,
      full_name:
        profile?.full_name ??
        (payload as unknown as { user_metadata?: { full_name?: string } })
          .user_metadata?.full_name ??
        null,
      avatar_url: profile?.avatar_url ?? null,
      phone: profile?.phone ?? null,
      kyc_status: profile?.kyc_status ?? "not_submitted",
      is_active: profile?.is_active ?? true,
      employee_id: profile?.employee_id ?? null,
      rider_id: profile?.rider_id ?? null,
      lender_id: profile?.lender_id ?? null,
      role_profile: roleProfile,
      created_at: profile?.created_at ?? new Date().toISOString(),
      updated_at: profile?.updated_at ?? new Date().toISOString(),
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders(req), "Content-Type": "application/json" },
    });
  }

  if (req.method === "PATCH") {
    let body: Record<string, unknown> = {};
    try {
      body = await req.json();
    } catch (_) {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        {
          status: 400,
          headers: { ...corsHeaders(req), "Content-Type": "application/json" },
        }
      );
    }

    const allowedFields = [
      "full_name",
      "avatar_url",
      "phone",
    ];
    const updates: Record<string, unknown> = {};
    for (const field of allowedFields) {
      if (field in body) {
        updates[field] = body[field];
      }
    }

    if (Object.keys(updates).length === 0) {
      return new Response(
        JSON.stringify({ error: "No updatable fields provided" }),
        {
          status: 400,
          headers: { ...corsHeaders(req), "Content-Type": "application/json" },
        }
      );
    }

    updates["updated_at"] = new Date().toISOString();

    const { data, error } = await supabase
      .from("profiles")
      .update(updates)
      .eq("id", payload.sub)
      .select()
      .maybeSingle();

    if (error) {
      return new Response(
        JSON.stringify({ error: "Failed to update profile", details: error.message }),
        {
          status: 500,
          headers: { ...corsHeaders(req), "Content-Type": "application/json" },
        }
      );
    }

    return new Response(JSON.stringify(data ?? updates), {
      status: 200,
      headers: { ...corsHeaders(req), "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ error: "Unhandled method" }), {
    status: 405,
    headers: { ...corsHeaders(req), "Content-Type": "application/json" },
  });
});
