import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Two Supabase clients — never conflate them (see docs/phases/00-architecture.md#7).
///
/// * [userClient]  — the supabase_flutter singleton. Auth + premium cloud sync
///   live here (BrickBack user project). Empty session for free/guest users.
/// * [catalogClient] — a plain second client, anon key, NO auth/session. Reads
///   the read-only LEGO catalog (whatabrick project). Built once in main().

/// The user-data project client (auth-bearing).
SupabaseClient get userClient => Supabase.instance.client;

late SupabaseClient _catalogClient;

/// The read-only catalog project client (anon, no session).
SupabaseClient get catalogClient => _catalogClient;

/// Called once from main() after [Supabase.initialize].
void initCatalogClient() {
  _catalogClient = SupabaseClient(
    Env.catalogSupabaseUrl,
    Env.catalogSupabaseAnonKey,
  );
}
