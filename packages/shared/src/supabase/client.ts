import { createClient, type SupabaseClientOptions } from "@supabase/supabase-js";
import type { Database } from "../db/types";

/**
 * Platform-agnostic typed Supabase client factory for the BrickBack USER project.
 * Used by the web marketing site if/when it needs client-side reads. The mobile
 * app uses supabase_flutter directly (see apps/mobile/lib/core/supabase.dart).
 */
export function createSupabaseClient(
  url: string,
  anonKey: string,
  options?: SupabaseClientOptions<"public">,
) {
  return createClient<Database>(url, anonKey, options);
}
