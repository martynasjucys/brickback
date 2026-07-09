import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/locale.dart';
import 'core/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Client-safe config (publishable keys) from the bundled .env asset.
  await dotenv.load(fileName: '.env');

  // User-data project — the supabase_flutter singleton (auth lives here).
  await Supabase.initialize(
    url: Env.userSupabaseUrl,
    // Value is a publishable key (sb_publishable_…); use the modern param.
    publishableKey: Env.userSupabaseAnonKey,
  );

  // Catalog project — a separate anon, session-less client (read-only).
  initCatalogClient();

  // Persisted UI language (English default).
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const BrickBackApp(),
  ));
}
