// supabase/functions/collections/assign-rider/index.ts
import { handleCors, corsHeaders } from "../../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../../_shared/jwt.ts";
import { getServiceClient } from "../../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound, conflict } from "../../_shared/errors.ts";
import { assignRiderSchema } from "../../_shared/validation.ts";

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

    if (!hasRole(payload, "employee", "head_manager")) {
      return forbidden("Only managers or admins can assign riders");
    }

    const url = new URL(req.url);
    const collectionId = url.pathname.split("/").filter(Boolean).pop();

    if (!collectionId) {
      return badRequest("Collection ID is required");
    }

    const body = await req.json();
    const parsed = assignRiderSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { rider_id } = parsed.data;
    const supabase = getServiceClient();

    const { data: collection, error: dbError } = await supabase
      .from("collections")
      .select("id, status, loan_id, lender_id")
      .eq("id", collectionId)
      .is("deleted_at", null)
      .single();

    if (dbError || !collection) {
      return notFound("Collection");
    }

    if (!["pending", "assigned"].includes(collection.status)) {
      return conflict(
        `Cannot assign rider to collection in '${collection.status}' status`
      );
    }

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

    const now = new Date().toISOString();
    const { error: updateError } = await supabase
      .from("collections")
      .update({
        assigned_rider_id: rider_id,
        status: "assigned",
        updated_at: now,
      })
      .eq("id", collectionId);

    if (updateError) {
      return serverError("Failed to assign rider");
    }

    await supabase.from("notifications").insert({
      user_id: rider.user_id,
      type: "collection_assigned",
      title: "New Collection Assignment",
      body: "You have been assigned a loan collection task.",
    });

    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "collection_rider_assigned",
      old_value: { status: collection.status, assigned_rider_id: null },
      new_value: { status: "assigned", assigned_rider_id: rider_id },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        message: "Rider assigned successfully",
        collection_id: collectionId,
        rider_id,
        status: "assigned",
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Collection assign rider error:", err);
    return serverError("Failed to assign rider");
  }
});
