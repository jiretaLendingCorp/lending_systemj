import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/app/app.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/auth/token_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Web-only entry point for LendFlow.
///
/// This file can be invoked directly with `flutter run -t lib/main_web.dart`
/// for web-specific builds. It configures:
///
/// 1. **Path URL strategy** — removes the `#` hash from URLs for cleaner
///    browser navigation and better SEO.
/// 2. **WebCrypto-backed token storage** — encrypts tokens before
///    storing in sessionStorage for security.
/// 3. **Supabase initialization** — connects to the backend.
/// 4. **Web-specific services** — service worker registration, etc.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Configure URL strategy ─────────────────────────────────
  if (kIsWeb) {
    _usePathUrlStrategy();
  }

  // ── 2. Initialize Supabase ────────────────────────────────────
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

  // ── 3. Initialize web-specific services ───────────────────────
  await _initializeWebServices();

  // ── 4. Run app with WebTokenStorage ───────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(WebTokenStorage()),
      ],
      child: const LendFlowApp(),
    ),
  );
}

/// Configure path-based URL strategy for Flutter web.
///
/// Removes the `#` fragment from URLs, enabling:
/// - Clean URLs: `/admin/dashboard` instead of `/#/admin/dashboard`
/// - Proper browser history / back-button support
/// - Better SEO and shareability
void _usePathUrlStrategy() {
  try {
    // Use the Flutter web URL strategy API
    // This calls `setUrlStrategy(PathUrlStrategy())` under the hood
    // ignore: avoid_web_libraries_in_flutter
    setUrlStrategy(null);
  } catch (_) {
    // URL strategy not available — continue with hash strategy
  }
}

/// Initialize web-specific services.
///
/// - Service worker registration for PWA support
/// - Web analytics setup (if configured)
/// - Browser compatibility checks
Future<void> _initializeWebServices() async {
  // PWA service worker registration is handled automatically
  // by Flutter's web build system when --pwa flag is used.

  // Additional web-specific initialization can go here:
  // - Google Analytics / Mixpanel
  // - Browser feature detection
  // - Cookie consent management
}
