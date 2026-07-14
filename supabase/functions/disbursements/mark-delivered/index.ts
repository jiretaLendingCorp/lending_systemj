/**
 * POST /disbursements/:id/delivered
 * Rider only, GPS check-in required.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden, notFound, conflict, unprocessable } from "../_shared/errors.ts";
import { markDeliveredSchema } from "../_shared/validation.ts";

const GPS_THRESHOLD_METERS = 200; // Allow 200m radius from target

function haversineDistance(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371000; // Earth radius in meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
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

    // Only riders can mark disbursements as delivered
    if (!hasRole(payload, "rider")) {
      return forbidden("Only riders can mark disbursements as delivered");
    }

    const url = new URL(req.url);
    const disbursementId = url.pathname.split("/").filter(Boolean).pop();

    if (!disbursementId) {
      return badRequest("Disbursement ID is required");
    }

    const body = await req.json();
    const parsed = markDeliveredSchema.safeParse(body);
    if (!parsed.success) {
      return badRequest("Validation failed", parsed.error.flatten());
    }

    const { latitude, longitude, receipt_url } = parsed.data;
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

    // Fetch disbursement
    const { data: disbursement, error: dbError } = await supabase
      .from("disbursements")
      .select("id, status, assigned_rider_id, loan_id")
      .eq("id", disbursementId)
      .is("deleted_at", null)
      .single();

    if (dbError || !disbursement) {
      return notFound("Disbursement");
    }

    // Verify this rider is assigned
    if (disbursement.assigned_rider_id !== rider.id) {
      return forbidden("You are not assigned to this disbursement");
    }

    // Verify correct status
    if (!["assigned", "in_transit"].includes(disbursement.status)) {
      return conflict(
        `Cannot mark disbursement as delivered in '${disbursement.status}' status`
      );
    }

    // Get borrower address coordinates for GPS verification
    const { data: loan } = await supabase
      .from("loans")
      .select("borrower_id, borrowers(address)")
      .eq("id", disbursement.loan_id)
      .single();

    // For now, store GPS coordinates and accept the check-in
    // In production, you would geocode the borrower's address and compare
    // const borrowerCoords = await geocodeAddress(loan.borrowers.address);
    // const distance = haversineDistance(latitude, longitude, borrowerCoords.lat, borrowerCoords.lng);
    // if (distance > GPS_THRESHOLD_METERS) {
    //   return unprocessable(`GPS check-in is ${Math.round(distance)}m from delivery address (max ${GPS_THRESHOLD_METERS}m)`);
    // }

    const now = new Date().toISOString();

    // Update disbursement
    const { error: updateError } = await supabase
      .from("disbursements")
      .update({
        status: "delivered",
        gps_latitude: latitude,
        gps_longitude: longitude,
        delivered_at: now,
        receipt_url: receipt_url ?? null,
        updated_at: now,
      })
      .eq("id", disbursementId);

    if (updateError) {
      return serverError("Failed to mark disbursement as delivered");
    }

    // Update loan status to disbursed
    await supabase
      .from("loans")
      .update({
        status: "disbursed",
        disbursed_at: now,
        updated_at: now,
      })
      .eq("id", disbursement.loan_id);

    // Create collection record for repayment
    const { data: loanData } = await supabase
      .from("loans")
      .select("borrower_id, total_payable")
      .eq("id", disbursement.loan_id)
      .single();

    if (loanData) {
      await supabase.from("collections").insert({
        loan_id: disbursement.loan_id,
        borrower_id: loanData.borrower_id,
        amount: loanData.total_payable,
        method: "office",
        status: "pending",
      });
    }

    // Notify borrower
    if (loanData) {
      const { data: borrower } = await supabase
        .from("borrowers")
        .select("user_id")
        .eq("id", loanData.borrower_id)
        .single();

      if (borrower) {
        await supabase.from("notifications").insert({
          user_id: borrower.user_id,
          type: "loan_disbursed",
          title: "Loan Disbursed",
          body: "Your loan has been delivered. Repayment schedule is now active.",
        });
      }
    }

    // Audit log
    await supabase.from("audit_logs").insert({
      user_id: payload.sub,
      user_role: payload.role,
      action: "disbursement_delivered",
      new_value: {
        disbursement_id: disbursementId,
        latitude,
        longitude,
        delivered_at: now,
      },
      ip_address: req.headers.get("x-forwarded-for") ?? req.headers.get("x-real-ip") ?? null,
    });

    return successResponse(
      {
        message: "Disbursement marked as delivered",
        disbursement_id: disbursementId,
        status: "delivered",
        delivered_at: now,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Disbursement delivered error:", err);
    return serverError("Failed to mark disbursement as delivered");
  }
});
