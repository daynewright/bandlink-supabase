export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      bands: {
        Row: {
          band_image_id: string | null
          created_at: string
          description: string | null
          id: string
          name: string
        }
        Insert: {
          band_image_id?: string | null
          created_at?: string
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          band_image_id?: string | null
          created_at?: string
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "bands_band_image_id_fkey"
            columns: ["band_image_id"]
            referencedRelation: "images"
            referencedColumns: ["id"]
          }
        ]
      }
      conversations: {
        Row: {
          band_id: string | null
          conversation_type: Database["public"]["Enums"]["conversation_type"]
          created_at: string
          event_id: string | null
          group_id: string | null
          id: string
          user_id_a: string | null
          user_id_b: string | null
        }
        Insert: {
          band_id?: string | null
          conversation_type: Database["public"]["Enums"]["conversation_type"]
          created_at?: string
          event_id?: string | null
          group_id?: string | null
          id?: string
          user_id_a?: string | null
          user_id_b?: string | null
        }
        Update: {
          band_id?: string | null
          conversation_type?: Database["public"]["Enums"]["conversation_type"]
          created_at?: string
          event_id?: string | null
          group_id?: string | null
          id?: string
          user_id_a?: string | null
          user_id_b?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "conversations_band_id_fkey"
            columns: ["band_id"]
            referencedRelation: "bands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_event_id_fkey"
            columns: ["event_id"]
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_group_id_fkey"
            columns: ["group_id"]
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_user_id_a_fkey"
            columns: ["user_id_a"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_user_id_b_fkey"
            columns: ["user_id_b"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          }
        ]
      }
      event_attendance: {
        Row: {
          created_at: string
          event_id: string
          status: Database["public"]["Enums"]["attendence_status"]
          user_id: string
        }
        Insert: {
          created_at?: string
          event_id: string
          status?: Database["public"]["Enums"]["attendence_status"]
          user_id: string
        }
        Update: {
          created_at?: string
          event_id?: string
          status?: Database["public"]["Enums"]["attendence_status"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_attendance_event_id_fkey"
            columns: ["event_id"]
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "event_attendance_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          }
        ]
      }
      events: {
        Row: {
          about: string | null
          band_id: string
          created_at: string
          creator_user_id: string
          description: string | null
          end_time: string | null
          event_date: string | null
          event_name: string
          event_type: string | null
          id: string
          location_address: string | null
          location_lat: number | null
          location_lng: number | null
          location_name: string | null
          owner_user_id: string | null
          start_time: string | null
        }
        Insert: {
          about?: string | null
          band_id: string
          created_at?: string
          creator_user_id: string
          description?: string | null
          end_time?: string | null
          event_date?: string | null
          event_name: string
          event_type?: string | null
          id?: string
          location_address?: string | null
          location_lat?: number | null
          location_lng?: number | null
          location_name?: string | null
          owner_user_id?: string | null
          start_time?: string | null
        }
        Update: {
          about?: string | null
          band_id?: string
          created_at?: string
          creator_user_id?: string
          description?: string | null
          end_time?: string | null
          event_date?: string | null
          event_name?: string
          event_type?: string | null
          id?: string
          location_address?: string | null
          location_lat?: number | null
          location_lng?: number | null
          location_name?: string | null
          owner_user_id?: string | null
          start_time?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "events_band_id_fkey"
            columns: ["band_id"]
            referencedRelation: "bands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_creator_user_id_fkey"
            columns: ["creator_user_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_owner_user_id_fkey"
            columns: ["owner_user_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          }
        ]
      }
      events_files: {
        Row: {
          created_at: string
          event_id: string
          file_id: string
        }
        Insert: {
          created_at?: string
          event_id: string
          file_id: string
        }
        Update: {
          created_at?: string
          event_id?: string
          file_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "events_files_event_id_fkey"
            columns: ["event_id"]
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_files_file_id_fkey"
            columns: ["file_id"]
            referencedRelation: "files"
            referencedColumns: ["id"]
          }
        ]
      }
      events_groups: {
        Row: {
          created_at: string
          event_id: string
          group_id: string
        }
        Insert: {
          created_at?: string
          event_id: string
          group_id: string
        }
        Update: {
          created_at?: string
          event_id?: string
          group_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "events_groups_event_id_fkey"
            columns: ["event_id"]
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_groups_group_id_fkey"
            columns: ["group_id"]
            referencedRelation: "groups"
            referencedColumns: ["id"]
          }
        ]
      }
      events_images: {
        Row: {
          created_at: string
          event_id: string
          image_id: string
        }
        Insert: {
          created_at?: string
          event_id: string
          image_id: string
        }
        Update: {
          created_at?: string
          event_id?: string
          image_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "events_images_event_id_fkey"
            columns: ["event_id"]
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_images_image_id_fkey"
            columns: ["image_id"]
            referencedRelation: "images"
            referencedColumns: ["id"]
          }
        ]
      }
      files: {
        Row: {
          created_at: string
          file_name: string
          file_path: string
          id: string
        }
        Insert: {
          created_at?: string
          file_name: string
          file_path: string
          id?: string
        }
        Update: {
          created_at?: string
          file_name?: string
          file_path?: string
          id?: string
        }
        Relationships: []
      }
      groups: {
        Row: {
          band_id: string
          created_at: string
          group_name: string
          id: string
        }
        Insert: {
          band_id: string
          created_at?: string
          group_name: string
          id?: string
        }
        Update: {
          band_id?: string
          created_at?: string
          group_name?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "groups_band_id_fkey"
            columns: ["band_id"]
            referencedRelation: "bands"
            referencedColumns: ["id"]
          }
        ]
      }
      images: {
        Row: {
          created_at: string
          id: string
          image_name: string | null
          image_path: string
        }
        Insert: {
          created_at?: string
          id?: string
          image_name?: string | null
          image_path: string
        }
        Update: {
          created_at?: string
          id?: string
          image_name?: string | null
          image_path?: string
        }
        Relationships: []
      }
      message_attachments: {
        Row: {
          created_at: string
          file_id: string | null
          id: string
          image_id: string | null
          message_id: string
        }
        Insert: {
          created_at?: string
          file_id?: string | null
          id?: string
          image_id?: string | null
          message_id: string
        }
        Update: {
          created_at?: string
          file_id?: string | null
          id?: string
          image_id?: string | null
          message_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_attachments_file_id_fkey"
            columns: ["file_id"]
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_attachments_image_id_fkey"
            columns: ["image_id"]
            referencedRelation: "images"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_attachments_message_id_fkey"
            columns: ["message_id"]
            referencedRelation: "messages"
            referencedColumns: ["id"]
          }
        ]
      }
      message_read_status: {
        Row: {
          is_read: boolean | null
          message_id: string
          user_id: string
        }
        Insert: {
          is_read?: boolean | null
          message_id: string
          user_id: string
        }
        Update: {
          is_read?: boolean | null
          message_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_read_status_message_id_fkey"
            columns: ["message_id"]
            referencedRelation: "messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "message_read_status_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          }
        ]
      }
      messages: {
        Row: {
          context: string
          conversation_id: string | null
          created_at: string
          id: string
          user_id: string
        }
        Insert: {
          context: string
          conversation_id?: string | null
          created_at?: string
          id?: string
          user_id: string
        }
        Update: {
          context?: string
          conversation_id?: string | null
          created_at?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          }
        ]
      }
      users_bands: {
        Row: {
          band_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          band_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          band_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "users_bands_band_id_fkey"
            columns: ["band_id"]
            referencedRelation: "bands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "users_bands_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          }
        ]
      }
      users_groups: {
        Row: {
          created_at: string
          group_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          group_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          group_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "users_groups_group_id_fkey"
            columns: ["group_id"]
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "users_groups_user_id_fkey"
            columns: ["user_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          }
        ]
      }
      users_profile: {
        Row: {
          about: string | null
          auth_user_id: string | null
          child_id: string | null
          created_at: string | null
          email: string | null
          first_name: string | null
          id: string
          instruments: string[] | null
          is_child: boolean
          last_name: string | null
          phone: string | null
          profile_image_id: string | null
          status: Database["public"]["Enums"]["user_status"]
          title: string | null
        }
        Insert: {
          about?: string | null
          auth_user_id?: string | null
          child_id?: string | null
          created_at?: string | null
          email?: string | null
          first_name?: string | null
          id?: string
          instruments?: string[] | null
          is_child?: boolean
          last_name?: string | null
          phone?: string | null
          profile_image_id?: string | null
          status?: Database["public"]["Enums"]["user_status"]
          title?: string | null
        }
        Update: {
          about?: string | null
          auth_user_id?: string | null
          child_id?: string | null
          created_at?: string | null
          email?: string | null
          first_name?: string | null
          id?: string
          instruments?: string[] | null
          is_child?: boolean
          last_name?: string | null
          phone?: string | null
          profile_image_id?: string | null
          status?: Database["public"]["Enums"]["user_status"]
          title?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "users_profile_auth_user_id_fkey"
            columns: ["auth_user_id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "users_profile_child_id_fkey"
            columns: ["child_id"]
            referencedRelation: "users_profile"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "users_profile_profile_image_id_fkey"
            columns: ["profile_image_id"]
            referencedRelation: "images"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      create_message_between_users: {
        Args: {
          p_sender_id: string
          p_receiver_id: string
          p_message_text: string
          p_file_id?: string
          p_image_id?: string
        }
        Returns: undefined
      }
      create_message_for_event: {
        Args: {
          p_event_id: string
          p_user_id: string
          p_message_text: string
          p_file_id?: string
          p_image_id?: string
        }
        Returns: undefined
      }
      create_message_for_group: {
        Args: {
          p_group_id: string
          p_user_id: string
          p_message_text: string
          p_file_id?: string
          p_image_id?: string
        }
        Returns: undefined
      }
      get_conversations_for_group: {
        Args: {
          p_group_id: string
        }
        Returns: {
          group_id: string
          group_name: string
          conversation_id: string
          users_count: number
          latest_message_date: string
        }[]
      }
      get_conversations_for_user: {
        Args: {
          p_user_id: string
        }
        Returns: {
          conversation_id: string
          other_user_name: string
          latest_message: string
          latest_message_date: string
        }[]
      }
      get_events_for_user_in_band: {
        Args: {
          p_band_id: string
          p_page_number: number
          p_items_per_page: number
          p_sort_order: string
        }
        Returns: {
          event_id: string
          event_name: string
          description: string
          event_date: string
          start_time: string
          end_time: string
          creator_user_id: string
          creator_name: string
          creator_picture: string
          attendees_count: number
          messages_count: number
          group_names: string[]
          event_type: string
          location_lat: number
          location_lng: number
          about: string
          location_address: string
          location_name: string
        }[]
      }
      get_group_conversations_by_user_id: {
        Args: {
          p_user_id: string
        }
        Returns: {
          group_id: string
          group_name: string
          conversation_id: string
          users_count: number
          latest_message_date: string
        }[]
      }
      get_messages_for_conversation_group: {
        Args: {
          p_conversation_id: string
          p_page_number: number
          p_items_per_page: number
        }
        Returns: {
          message_id: string
          user_id: string
          user_name: string
          message: string
          created_at: string
        }[]
      }
      get_messages_for_conversation_user: {
        Args: {
          p_conversation_id: string
          p_page_number: number
          p_items_per_page: number
        }
        Returns: {
          message_id: string
          sender_id: string
          sender_name: string
          message: string
          created_at: string
        }[]
      }
      get_messages_for_event: {
        Args: {
          p_event_id: string
          p_page_number: number
          p_items_per_page: number
        }
        Returns: {
          conversation_id: string
          event_id: string
          message: string
          sender_user_id: string
          sender_name: string
          sender_image_path: string
          file_name: string
          file_path: string
          image_name: string
          image_path: string
          created_at: string
        }[]
      }
      get_single_event_with_details: {
        Args: {
          p_event_id: string
        }
        Returns: {
          event_id: string
          event_name: string
          description: string
          event_date: string
          start_time: string
          end_time: string
          creator_user_id: string
          creator_name: string
          creator_picture: string
          attendees_count: number
          attendees: Json
          files: Json
          images: Json
          messages_count: number
          event_type: string
          location_lat: number
          location_lng: number
          about: string
          location_address: string
          location_name: string
        }[]
      }
      get_users_for_event: {
        Args: {
          p_event_id: string
        }
        Returns: {
          user_id: string
          full_name: string
          image_path: string
          attendance_status: string
        }[]
      }
    }
    Enums: {
      attendence_status: "ATTENDING" | "NOT_ATTENDING" | "MAYBE_ATTENDING"
      conversation_type: "GROUP" | "EVENT" | "USER"
      user_status: "ACTIVE" | "DEACTIVATED" | "BLOCKED"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

