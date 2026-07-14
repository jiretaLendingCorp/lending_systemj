// lib/core/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/app/app_router.dart';
import 'package:jireta_loan/core/app/app_theme.dart';
import 'package:jireta_loan/core/utils/constants.dart';

class JiretaLoanApp extends ConsumerWidget {
  const JiretaLoanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(AppRouter.provider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      routerConfig: router,

      locale: const Locale('en', 'PH'),
      supportedLocales: const [
        Locale('en', 'PH'),
        Locale('en'),
      ],

      builder: (context, child) {
        return MediaQuery(
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
