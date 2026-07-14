// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:jireta_loan/core/app/app.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/auth/token_storage.dart';

import 'url_strategy_native.dart'
    if (dart.library.js_util) 'url_strategy_web.dart' as url_strategy;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await mainWeb();
  } else {
    await mainMobile();
  }
}

Future<void> mainWeb() async {
  if (kIsWeb) {
    url_strategy.usePathUrlStrategy();
  }

  await _initializeSupabase();

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(WebTokenStorage()),
      ],
      child: const JiretaLoanApp(),
    ),
  );
}

Future<void> mainMobile() async {
  await _initializeSupabase();

  const secureStorage = FlutterSecureStorage();
  final mobileStorage = MobileTokenStorage(secureStorage);

  await _requestMobilePermissions();

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(mobileStorage),
      ],
      child: const JiretaLoanApp(),
    ),
  );
}

Future<void> _initializeSupabase() async {
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
}

Future<void> _requestMobilePermissions() async {}
