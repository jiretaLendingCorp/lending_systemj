/**
 * POST /notifications/send-push
 * FCM/APNs push, no sensitive data in payload.
 */
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { authenticateRequest, hasRole } from "../_shared/jwt.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { badRequest, successResponse, serverError, forbidden } from "../_shared/errors.ts";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";

interface PushPayload {
  user_id: string;
  title: string;
  body: string;
  type: string;
  data?: Record<string, string>;
}

Deno.serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return badRequest("Method not allowed");
    }

    // Can be called by system or by admin/manager
    const cronSecret = req.headers.get("x-cron-secret");
    const isCron = cronSecret === Deno.env.get("CRON_SECRET");

    if (!isCron) {
      const authResult = await authenticateRequest(req);
      if ("error" in authResult) return authResult.error;
      if (!hasRole(authResult.payload, "admin", "manager", "system")) {
        return forbidden("Insufficient permissions");
      }
    }

    const body: PushPayload = await req.json();

    if (!body.user_id || !body.title || !body.body || !body.type) {
      return badRequest("user_id, title, body, and type are required");
    }

    const supabase = getServiceClient();

    // Get user's FCM tokens (stored in user metadata or a separate table)
    const { data: user } = await supabase.auth.admin.getUserById(body.user_id);
    if (!user) {
      return badRequest("User not found");
    }

    const fcmTokens: string[] = user.user?.app_metadata?.fcm_tokens ?? [];

    if (fcmTokens.length === 0) {
      // No push tokens registered — skip silently
      return successResponse(
        { message: "No push tokens registered for user", sent: 0 },
        200,
        corsHeaders(req)
      );
    }

    // Build FCM message — NO sensitive data in payload
    const pushData: Record<string, string> = {
      type: body.type,
      ...(body.data ?? {}),
    };

    let sentCount = 0;
    const invalidTokens: string[] = [];

    for (const token of fcmTokens) {
      try {
        const fcmResponse = await fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            Authorization: `key=${FCM_SERVER_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title: body.title,
              body: body.body,
            },
            data: pushData,
            android: {
              priority: "high",
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
          }),
        });

        if (fcmResponse.ok) {
          sentCount++;
        } else {
          const errorData = await fcmResponse.json();
          // Remove invalid tokens
          if (
            errorData.results?.[0]?.error === "InvalidRegistration" ||
            errorData.results?.[0]?.error === "NotRegistered"
          ) {
            invalidTokens.push(token);
          }
        }
      } catch {
        // Continue with other tokens
      }
    }

    // Remove invalid tokens from user metadata
    if (invalidTokens.length > 0) {
      const validTokens = fcmTokens.filter((t) => !invalidTokens.includes(t));
      await supabase.auth.admin.updateUserById(body.user_id, {
        app_metadata: { fcm_tokens: validTokens },
      });
    }

    // Also create in-app notification
    await supabase.from("notifications").insert({
      user_id: body.user_id,
      type: body.type,
      title: body.title,
      body: body.body,
    });

    // Audit log
    await supabase.from("audit_logs").insert({
      user_id: body.user_id,
      user_role: "system",
      action: "push_notification_sent",
      new_value: { type: body.type, sent: sentCount, tokens: fcmTokens.length },
    });

    return successResponse(
      {
        message: "Push notification sent",
        sent: sentCount,
        total_tokens: fcmTokens.length,
        invalid_tokens_removed: invalidTokens.length,
      },
      200,
      corsHeaders(req)
    );
  } catch (err) {
    console.error("Send push error:", err);
    return serverError("Failed to send push notification");
  }
});
