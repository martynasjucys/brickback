// Generated Supabase types for the BrickBack USER project (nthbhcqufiuyrnioxglm).
// Regenerate with:  pnpm db:types   (see root package.json)
// Do NOT hand-edit. The LEGO catalog lives in a separate project; its types are
// not generated here (the Flutter app reads it with untyped/hand-modeled queries).

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      party_assignments: {
        Row: {
          created_at: string
          filter_kind: string
          filter_value: Json
          id: string
          label: string
          member_id: string | null
          party_id: string
          target_qty: number | null
        }
        Insert: {
          created_at?: string
          filter_kind: string
          filter_value?: Json
          id?: string
          label: string
          member_id?: string | null
          party_id: string
          target_qty?: number | null
        }
        Update: {
          created_at?: string
          filter_kind?: string
          filter_value?: Json
          id?: string
          label?: string
          member_id?: string | null
          party_id?: string
          target_qty?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "party_assignments_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "party_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_assignments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "party_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      party_contributions: {
        Row: {
          assignment_id: string | null
          color_id: number
          color_name: string | null
          created_at: string
          id: string
          member_id: string | null
          part_item_id: number
          part_name: string | null
          party_id: string
          qty: number
        }
        Insert: {
          assignment_id?: string | null
          color_id: number
          color_name?: string | null
          created_at?: string
          id?: string
          member_id?: string | null
          part_item_id: number
          part_name?: string | null
          party_id: string
          qty: number
        }
        Update: {
          assignment_id?: string | null
          color_id?: number
          color_name?: string | null
          created_at?: string
          id?: string
          member_id?: string | null
          part_item_id?: number
          part_name?: string | null
          party_id?: string
          qty?: number
        }
        Relationships: [
          {
            foreignKeyName: "party_contributions_assignment_id_fkey"
            columns: ["assignment_id"]
            isOneToOne: false
            referencedRelation: "party_assignments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_contributions_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "party_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_contributions_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "party_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      party_members: {
        Row: {
          avatar_seed: string | null
          display_name: string | null
          id: string
          joined_at: string
          party_id: string
          role: string
          user_id: string
        }
        Insert: {
          avatar_seed?: string | null
          display_name?: string | null
          id?: string
          joined_at?: string
          party_id: string
          role?: string
          user_id: string
        }
        Update: {
          avatar_seed?: string | null
          display_name?: string | null
          id?: string
          joined_at?: string
          party_id?: string
          role?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "party_members_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "party_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      party_sessions: {
        Row: {
          created_at: string
          host_user_id: string
          id: string
          join_code: string
          name: string
          rebuild_set_id: string | null
          set_item_id: number
          status: string
        }
        Insert: {
          created_at?: string
          host_user_id: string
          id?: string
          join_code: string
          name: string
          rebuild_set_id?: string | null
          set_item_id: number
          status?: string
        }
        Update: {
          created_at?: string
          host_user_id?: string
          id?: string
          join_code?: string
          name?: string
          rebuild_set_id?: string | null
          set_item_id?: number
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "party_sessions_rebuild_set_id_fkey"
            columns: ["rebuild_set_id"]
            isOneToOne: false
            referencedRelation: "rebuild_sets"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          id: string
          is_premium: boolean
          updated_at: string
        }
        Insert: {
          created_at?: string
          id: string
          is_premium?: boolean
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          is_premium?: boolean
          updated_at?: string
        }
        Relationships: []
      }
      rebuild_minifigs: {
        Row: {
          deleted: boolean
          have_qty: number
          minifig_item_id: number
          rebuild_set_id: string
          updated_at: string
        }
        Insert: {
          deleted?: boolean
          have_qty?: number
          minifig_item_id: number
          rebuild_set_id: string
          updated_at?: string
        }
        Update: {
          deleted?: boolean
          have_qty?: number
          minifig_item_id?: number
          rebuild_set_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "rebuild_minifigs_rebuild_set_id_fkey"
            columns: ["rebuild_set_id"]
            isOneToOne: false
            referencedRelation: "rebuild_sets"
            referencedColumns: ["id"]
          },
        ]
      }
      rebuild_set_parts: {
        Row: {
          color_id: number
          deleted: boolean
          have_qty: number
          part_item_id: number
          rebuild_set_id: string
          updated_at: string
        }
        Insert: {
          color_id: number
          deleted?: boolean
          have_qty?: number
          part_item_id: number
          rebuild_set_id: string
          updated_at?: string
        }
        Update: {
          color_id?: number
          deleted?: boolean
          have_qty?: number
          part_item_id?: number
          rebuild_set_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "rebuild_set_parts_rebuild_set_id_fkey"
            columns: ["rebuild_set_id"]
            isOneToOne: false
            referencedRelation: "rebuild_sets"
            referencedColumns: ["id"]
          },
        ]
      }
      rebuild_sets: {
        Row: {
          deleted: boolean
          id: string
          set_item_id: number
          total_parts: number
          updated_at: string
          user_id: string
          verified_at: string | null
        }
        Insert: {
          deleted?: boolean
          id: string
          set_item_id: number
          total_parts?: number
          updated_at?: string
          user_id: string
          verified_at?: string | null
        }
        Update: {
          deleted?: boolean
          id?: string
          set_item_id?: number
          total_parts?: number
          updated_at?: string
          user_id?: string
          verified_at?: string | null
        }
        Relationships: []
      }
      verifications: {
        Row: {
          completion_pct: number
          deleted: boolean
          flags: Json
          id: string
          minifigs_found: number | null
          minifigs_needed: number | null
          notes: string | null
          parts_found: number | null
          parts_needed: number | null
          rebuild_set_id: string
          set_item_id: number
          updated_at: string
          user_id: string
          verified_at: string
        }
        Insert: {
          completion_pct?: number
          deleted?: boolean
          flags?: Json
          id: string
          minifigs_found?: number | null
          minifigs_needed?: number | null
          notes?: string | null
          parts_found?: number | null
          parts_needed?: number | null
          rebuild_set_id: string
          set_item_id: number
          updated_at?: string
          user_id: string
          verified_at?: string
        }
        Update: {
          completion_pct?: number
          deleted?: boolean
          flags?: Json
          id?: string
          minifigs_found?: number | null
          minifigs_needed?: number | null
          notes?: string | null
          parts_found?: number | null
          parts_needed?: number | null
          rebuild_set_id?: string
          set_item_id?: number
          updated_at?: string
          user_id?: string
          verified_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "verifications_rebuild_set_id_fkey"
            columns: ["rebuild_set_id"]
            isOneToOne: false
            referencedRelation: "rebuild_sets"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      _party_display_name: { Args: never; Returns: string }
      create_party: {
        Args: { p_name: string; p_rebuild_set_id: string }
        Returns: {
          created_at: string
          host_user_id: string
          id: string
          join_code: string
          name: string
          rebuild_set_id: string | null
          set_item_id: number
          status: string
        }
        SetofOptions: {
          from: "*"
          to: "party_sessions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      is_party_member: { Args: { p_party_id: string }; Returns: boolean }
      join_party: {
        Args: { p_code: string }
        Returns: {
          created_at: string
          host_user_id: string
          id: string
          join_code: string
          name: string
          rebuild_set_id: string | null
          set_item_id: number
          status: string
        }
        SetofOptions: {
          from: "*"
          to: "party_sessions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      party_have_counts: {
        Args: { p_party_id: string }
        Returns: {
          color_id: number
          have: number
          part_item_id: number
        }[]
      }
      party_progress: {
        Args: { p_party_id: string }
        Returns: {
          have: number
          total: number
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
