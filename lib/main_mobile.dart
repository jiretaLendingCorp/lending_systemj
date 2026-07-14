// lib/main_mobile.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jireta_loan/core/app/app.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/auth/token_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await _initializeFirebase();

  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  final mobileStorage = MobileTokenStorage(secureStorage);

  await _requestPermissions();

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(mobileStorage),
      ],
      child: const JiretaLoanApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  try {
  } catch (_) {
  }
}

Future<void> _requestPermissions() async {
  try {
  } catch (_) {
  }
}
