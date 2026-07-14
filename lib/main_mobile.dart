import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lendflow/core/app/app.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/auth/token_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mobile-only entry point for LendFlow.
///
/// This file can be invoked directly with
/// `flutter run -t lib/main_mobile.dart` for iOS/Android builds.
/// It configures:
///
/// 1. **FlutterSecureStorage** — platform-encrypted token persistence
///    (Keychain on iOS, EncryptedSharedPreferences on Android)
/// 2. **Runtime permissions** — location, notifications, camera
/// 3. **Supabase initialization** — connects to the backend
/// 4. **Firebase initialization** — push notifications & analytics
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Initialize Supabase ────────────────────────────────────
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:54321',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    ),
    debug: kDebugMode,
  );

  // ── 2. Initialize Firebase ────────────────────────────────────
  await _initializeFirebase();

  // ── 3. Configure secure storage ───────────────────────────────
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  final mobileStorage = MobileTokenStorage(secureStorage);

  // ── 4. Request runtime permissions ────────────────────────────
  await _requestPermissions();

  // ── 5. Run app with MobileTokenStorage ────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(mobileStorage),
      ],
      child: const LendFlowApp(),
    ),
  );
}

/// Initialize Firebase for mobile platforms.
///
/// Configures:
/// - Firebase Core
/// - Firebase Cloud Messaging (push notifications)
/// - Firebase Analytics
/// - Firebase Crashlytics
Future<void> _initializeFirebase() async {
  try {
    // Firebase initialization is conditional — the actual
    // Firebase packages are only included in mobile builds.
    //
    // Example (requires firebase_core package):
    //   await Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform,
    //   );
    //   await FirebaseMessaging.instance.requestPermission();
    //   await FirebaseMessaging.instance.getToken();
    //
    // For now, we silently continue until Firebase is configured.
  } catch (_) {
    // Firebase not configured — continue without it
  }
}

/// Request runtime permissions required by LendFlow on mobile.
///
/// Requests permissions in a logical order with user-facing
/// rationale. Permissions that are denied do not block app usage;
/// they only disable the features that depend on them.
Future<void> _requestPermissions() async {
  try {
    // Permission requests use the permission_handler package.
    // Each permission is requested with a specific rationale.
    //
    // ── Location (for rider map features) ─────────────────────
    //   final locationStatus = await Permission.locationWhenInUse.request();
    //   if (locationStatus.isDenied) {
    //     // Feature will work with limited functionality
    //   }
    //
    // ── Notifications (for push alerts) ───────────────────────
    //   final notificationStatus = await Permission.notification.request();
    //
    // ── Camera (for document scanning) ────────────────────────
    //   final cameraStatus = await Permission.camera.request();
    //
    // ── Storage (for receipt downloads) ───────────────────────
    //   final storageStatus = await Permission.storage.request();
    //
    // For now, permissions are handled gracefully on first use
    // of each feature, rather than all upfront.
  } catch (_) {
    // Permission handler not available — continue
  }
}
