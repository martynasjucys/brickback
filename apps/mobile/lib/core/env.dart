import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed accessor over the bundled `.env` asset (client-safe / publishable keys
/// only — see docs/phases/01-foundation.md#env). Never put server secrets here.
class Env {
  Env._();

  static String _req(String key) {
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) {
      throw StateError('Missing env var: $key (check apps/mobile/.env)');
    }
    return v;
  }

  // User-data project (BrickBack) — auth + premium cloud sync.
  static String get userSupabaseUrl => _req('USER_SUPABASE_URL');
  static String get userSupabaseAnonKey => _req('USER_SUPABASE_ANON_KEY');

  // Catalog project (whatabrick) — read-only LEGO catalog.
  static String get catalogSupabaseUrl => _req('CATALOG_SUPABASE_URL');
  static String get catalogSupabaseAnonKey => _req('CATALOG_SUPABASE_ANON_KEY');

  // Public R2 CDN base for catalog images: `$cdnUrl/${item_images.storage_key}`.
  static String get cdnUrl => _req('CDN_URL');
}
