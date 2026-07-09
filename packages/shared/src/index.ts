// @brickback/shared — types + Supabase client factory shared by the web surfaces.
// (The Flutter app has its own Dart models and does not consume this package.)
export type { Database } from "./db/types";
export { createSupabaseClient } from "./supabase/client";
