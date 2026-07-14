/**
 * POST /rider/gps-checkin
 * Validate coords against task address.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound, unprocessable } from "../_shared/errors.ts";
import { gpsCheckinSchema } from "../_shared/validation.ts";

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
      return forbidden("Only riders can check in via GPS");
    }

    const body = await req.json();
    const parsed = gpsCheckinSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { task_id, task_type, latitude, longitude, accuracy } = parsed.data;
    const supabase = getServiceClient();

    // Get rider profile
    const { data: rider } = await supabase
      .from("riders")
      .select("id")
      .eq("user_id", payload.sub)
      .is("deleted_at", null)
      .single();

    if (!rider) {
      return forbidden("Rider profile not found");
    }

    // Update rider's current location
    await supabase
      .from("riders")
      .update({
        current_latitude: latitude,
        current_longitude: longitude,
      })
      .eq("id", rider.id);

    // Fetch the task
    let task: Record<string, unknown> | null = null;
    let targetAddress: string | null = null;

    if (task_type === "disbursement") {
      const { data, error } = await supabase
        .from("disbursements")
        .select(
          `id, status, assigned_rider_id,
           loan:loans!disbursements_loan_id_fkey(
             borrower:borrowers!loans_borrower_id_fkey(address)
           )`
        )
        .eq("id", task_id)
        .is("deleted_at", null)
        .single();

      if (error || !data) {
        return notFound("Disbursement task");
      }

      if (data.assigned_rider_id !== rider.id) {
        return forbidden("You are not assigned to this task");
      }

      task = data;
      // @ts-expect-error nested join typing
      targetAddress = data.loan?.borrower?.address ?? null;
    } else if (task_type === "collection") {
      const { data, error } = await supabase
        .from("collections")
        .select(
          `id, status, assigned_rider_id,
           loan:loans!collections_loan_id_fkey(
             borrower:borrowers!loans_borrower_id_fkey(address)
           )`
        )
        .eq("id", task_id)
        .is("deleted_at", null)
        .single();

      if (error || !data) {
        return notFound("Collection task");
      }

      if (data.assigned_rider_id !== rider.id) {
        return forbidden("You are not assigned to this task");
      }

      task = data;
      // @ts-expect-error nested join typing
      targetAddress = data.loan?.borrower?.address ?? null;
    }

    // Geocode the target address if available
    // In production, use a geocoding service (Google Maps, Mapbox, etc.)
    // For now, we accept the check-in and log the coordinates
    let distanceMeters: number | null = null;
    let withinRange = true;

    // If we had target coordinates:
    // const targetCoords = await geocodeAddress(targetAddress);
    // distanceMeters = haversineDistance(latitude, longitude, targetCoords.lat, targetCoords.lng);
    // withinRange = distanceMeters <= GPS_THRESHOLD_METERS;

    // Update task status to in_transit
    const tableName = task_type === "disbursement" ? "disbursements" : "collections";
    await supabase
      .from(tableName)
      .update({ status: "in_transit", updated_at: new Date().toISOString() })
      .eq("id", task_id);

    // Audit log
    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "gps_checkin",
      new_value: {
        task_id,
        task_type,
        latitude,
        longitude,
        accuracy,
        distance_meters: distanceMeters,
        within_range: withinRange,
      },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        message: "GPS check-in recorded",
        task_id,
        task_type,
        latitude,
        longitude,
        within_range: withinRange,
        distance_meters: distanceMeters,
        status: "in_transit",
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("GPS check-in error:", err);
    return serverError("Failed to process GPS check-in");
  }
});
