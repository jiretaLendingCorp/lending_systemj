/**
 * POST /disbursements/:id/assign
 * Manager/admin only, assign a rider to a disbursement.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound, conflict } from "../_shared/errors.ts";
import { assignRiderSchema } from "../_shared/validation.ts";

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    const authResult = await authenticateRequest(req);
    if ("error" in authResult) return authResult.error;
    const { payload } = authResult;

    if (!hasRole(payload, "manager", "admin")) {
      return forbidden("Only managers or admins can assign riders");
    }

    const url = new URL(req.url);
    const disbursementId = url.pathname.split("/").filter(Boolean).pop();

    if (!disbursementId) {
      return badRequest("Disbursement ID is required");
    }

    const body = await req.json();
    const parsed = assignRiderSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { rider_id } = parsed.data;
    const supabase = getServiceClient();

    // Verify disbursement exists and is in correct status
    const { data: disbursement, error: dbError } = await supabase
      .from("disbursements")
      .select("id, status, loan_id")
      .eq("id", disbursementId)
      .is("deleted_at", null)
      .single();

    if (dbError || !disbursement) {
      return notFound("Disbursement");
    }

    if (!["pending", "assigned"].includes(disbursement.status)) {
      return conflict(
        `Cannot assign rider to disbursement in '${disbursement.status}' status`
      );
    }

    // Verify rider exists and is available
    const { data: rider, error: riderError } = await supabase
      .from("riders")
      .select("id, user_id, is_available")
      .eq("id", rider_id)
      .is("deleted_at", null)
      .single();

    if (riderError || !rider) {
      return notFound("Rider");
    }

    if (!rider.is_available) {
      return conflict("Rider is not currently available");
    }

    // Assign rider
    const now = new Date().toISOString();
    const { error: updateError } = await supabase
      .from("disbursements")
      .update({
        assigned_rider_id: rider_id,
        status: "assigned",
        updated_at: now,
      })
      .eq("id", disbursementId);

    if (updateError) {
      return serverError("Failed to assign rider");
    }

    // Notify the rider
    await supabase.from("notifications").insert({
      user_id: rider.user_id,
      type: "disbursement_assigned",
      title: "New Delivery Assignment",
      body: "You have been assigned a loan disbursement for delivery.",
    });

    // Audit log
    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "disbursement_rider_assigned",
      old_value: { status: disbursement.status, assigned_rider_id: null },
      new_value: { status: "assigned", assigned_rider_id: rider_id },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        message: "Rider assigned successfully",
        disbursement_id: disbursementId,
        rider_id,
        status: "assigned",
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Disbursement assign rider error:", err);
    return serverError("Failed to assign rider");
  }
});
