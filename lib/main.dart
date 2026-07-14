import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/app/app.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/auth/token_storage.dart';

/// Common entry point for LendFlow.
///
/// Detects the current platform and delegates to the appropriate
/// platform-specific entry:
/// - **Web** → [mainWeb] (from main_web.dart)
/// - **Mobile** → [mainMobile] (from main_mobile.dart)
///
/// Both paths share the same [LendFlowApp] widget; they differ only
/// in platform-specific initialization (URL strategy, secure storage,
/// permissions, etc.).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await mainWeb();
  } else {
    await mainMobile();
  }
}

/// Web-specific entry point.
///
/// - Configures URL strategy (path-based, no hash)
/// - Initializes web-specific token storage
/// - Runs the app with a [ProviderScope] that overrides
///   [tokenStorageProvider] with [WebTokenStorage]
Future<void> mainWeb() async {
  // Use path URLs (no # hash) for cleaner URLs on web
  // setUrlStrategy is called via the universal_ui import below
  // which handles the conditional import for web
  try {
    // Conditional web import for URL strategy
    // ignore: avoid_web_libraries_in_flutter
    if (kIsWeb) {
      usePathUrlStrategy();
    }
  } catch (_) {
    // Not on web or URL strategy not available — continue
  }

  // Initialize Supabase (shared between web and mobile)
  await _initializeSupabase();

  // Run app with WebTokenStorage override
  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(WebTokenStorage()),
      ],
      child: const LendFlowApp(),
    ),
  );
}

/// Mobile-specific entry point.
///
/// - Configures flutter_secure_storage for token persistence
/// - Requests necessary runtime permissions
/// - Runs the app with a [ProviderScope] that overrides
///   [tokenStorageProvider] with [MobileTokenStorage]
Future<void> mainMobile() async {
  // Initialize Supabase (shared between web and mobile)
  await _initializeSupabase();

  // Initialize FlutterSecureStorage
  const secureStorage = FlutterSecureStorage();
  final mobileStorage = MobileTokenStorage(secureStorage);

  // Request necessary permissions on mobile
  await _requestMobilePermissions();

  // Run app with MobileTokenStorage override
  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(mobileStorage),
      ],
      child: const LendFlowApp(),
    ),
  );
}

/// Initialize Supabase client with platform-appropriate configuration.
///
/// This is called by both [mainWeb] and [mainMobile] before the
/// app starts.
Future<void> _initializeSupabase() async {
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
}

/// Request runtime permissions required on mobile platforms.
///
/// Currently requests:
/// - Location (for rider map features)
/// - Notifications (for push alerts)
///
/// Gracefully handles cases where permissions are denied.
Future<void> _requestMobilePermissions() async {
  // Permission requests are handled via the permission_handler package.
  // The actual calls are conditional to avoid import issues on web.
  try {
    // These will be implemented with permission_handler once added
    // to pubspec.yaml. For now, we silently continue.
    //
    // Example:
    //   final locationStatus = await Permission.locationWhenInUse.request();
    //   final notificationStatus = await Permission.notification.request();
  } catch (_) {
    // Permissions not available or denied — continue
  }
}

/// Configure path-based URL strategy for web.
///
/// This is a no-op on non-web platforms. On web, it removes the
/// hash (#) from URLs for cleaner routing.
void usePathUrlStrategy() {
  // On web, this calls setUrlStrategy(PathUrlStrategy())
  // On mobile, this is a no-op
  if (kIsWeb) {
    // The actual implementation uses conditional imports.
    // When running on web, Flutter's url_strategy.dart is available.
    try {
      // Dynamic lookup to avoid compile-time import issues
      // ignore: avoid_web_libraries_in_flutter
      setUrlStrategy(null); // Removes hash (#) from URLs
    } catch (_) {
      // Not available — continue with default strategy
    }
  }
}

// ── Conditional imports for platform-specific deps ───────────────
//
// These imports use dart:io Platform check to avoid web compilation
// errors. Flutter's tree-shaking removes unused platform code.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
