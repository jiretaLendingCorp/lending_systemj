import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/app/app_router.dart';
import 'package:lendflow/core/app/app_theme.dart';
import 'package:lendflow/core/utils/constants.dart';

/// Root [MaterialApp.router] widget for LendFlow.
///
/// Configures:
/// - Light / dark theme from [AppTheme]
/// - GoRouter from [AppRouter]
/// - Riverpod [ProviderScope] (added upstream in main.dart)
/// - App-level locale and builder
class LendFlowApp extends ConsumerWidget {
  const LendFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(AppRouter.provider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────────────
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      // ── Router ────────────────────────────────────────────────
      routerConfig: router,

      // ── Localization ──────────────────────────────────────────
      locale: const Locale('en', 'PH'),
      supportedLocales: const [
        Locale('en', 'PH'),
        Locale('en'),
      ],

      // ── Builder ───────────────────────────────────────────────
      builder: (context, child) {
        // Global overlay for loading indicators, banners, etc.
        return MediaQuery(
          // Prevent system font scaling from breaking layouts
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
