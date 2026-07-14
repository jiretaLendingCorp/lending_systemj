// supabase/functions/collections/mark-collected/index.ts
import { handleCors, corsHeaders } from "../../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../../_shared/jwt.ts";
import { getServiceClient } from "../../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound, conflict } from "../../_shared/errors.ts";
import { markCollectedSchema } from "../../_shared/validation.ts";

const GPS_THRESHOLD_METERS = 200;

function haversineDistance(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

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

    if (!hasRole(payload, "rider")) {
      return forbidden("Only riders can mark collections as collected");
    }

    const url = new URL(req.url);
    const collectionId = url.pathname.split("/").filter(Boolean).pop();

    if (!collectionId) {
      return badRequest("Collection ID is required");
    }

    const body = await req.json();
    const parsed = markCollectedSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { latitude, longitude, photo_receipt_url, amount, method } = parsed.data;
    const supabase = getServiceClient();

    const { data: rider } = await supabase
      .from("riders")
      .select("id")
      .eq("user_id", payload.sub)
      .is("deleted_at", null)
      .single();

    if (!rider) {
      return forbidden("Rider profile not found");
    }

    const { data: collection, error: dbError } = await supabase
      .from("collections")
      .select("id, status, assigned_rider_id, loan_id, lender_id, amount")
      .eq("id", collectionId)
      .is("deleted_at", null)
      .single();

    if (dbError || !collection) {
      return notFound("Collection");
    }

    if (collection.assigned_rider_id !== rider.id) {
      return forbidden("You are not assigned to this collection");
    }

    if (!["assigned", "in_transit"].includes(collection.status)) {
      return conflict(
        `Cannot mark collection as collected in '${collection.status}' status`
      );
    }

    if (amount > Number(collection.amount)) {
      return badRequest("Collection amount exceeds the expected amount");
    }

    const now = new Date().toISOString();

    const { error: updateError } = await supabase
      .from("collections")
      .update({
        status: "collected",
        gps_latitude: latitude,
        gps_longitude: longitude,
        collected_at: now,
        photo_receipt_url,
        amount,
        method,
        updated_at: now,
      })
      .eq("id", collectionId);

    if (updateError) {
      return serverError("Failed to mark collection as collected");
    }

    await supabase.from("payments").insert({
      loan_id: collection.loan_id,
      lender_id: collection.lender_id,
      amount,
      method,
      status: "completed",
      collected_by: payload.sub,
      collected_at: now,
      receipt_url: photo_receipt_url,
    });

    const { data: lender } = await supabase
      .from('lenders')
      .select("user_id")
      .eq("id", collection.lender_id)
      .single();

    if (lender) {
      await supabase.from("notifications").insert({
        user_id: lender.user_id,
        type: "payment_collected",
        title: "Payment Collected",
        body: `A payment of ₱${amount.toLocaleString()} has been collected from you via ${method}.`,
      });
    }

    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "collection_collected",
      new_value: {
        collection_id: collectionId,
        amount,
        method,
        latitude,
        longitude,
        collected_at: now,
      },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        message: "Collection marked as collected",
        collection_id: collectionId,
        status: "collected",
        amount,
        collected_at: now,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Collection collected error:", err);
    return serverError("Failed to mark collection as collected");
  }
});
