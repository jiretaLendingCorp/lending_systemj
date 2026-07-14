// lib/main_web.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/app/app.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/auth/token_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'url_strategy_native.dart'
    if (dart.library.js_util) 'url_strategy_web.dart' as url_strategy;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    url_strategy.usePathUrlStrategy();
  }

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:54321',
    ),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    ),
    debug: kDebugMode,
  );

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(WebTokenStorage()),
      ],
      child: const JiretaLoanApp(),
    ),
  );
}
