
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE TYPE "public"."attendence_status" AS ENUM (
    'ATTENDING',
    'NOT_ATTENDING',
    'MAYBE_ATTENDING'
);

ALTER TYPE "public"."attendence_status" OWNER TO "postgres";

CREATE TYPE "public"."conversation_type" AS ENUM (
    'GROUP',
    'EVENT',
    'USER'
);

ALTER TYPE "public"."conversation_type" OWNER TO "postgres";

CREATE TYPE "public"."user_status" AS ENUM (
    'ACTIVE',
    'DEACTIVATED',
    'BLOCKED'
);

ALTER TYPE "public"."user_status" OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."create_message_between_users"("p_sender_id" "uuid", "p_receiver_id" "uuid", "p_message_text" "text", "p_file_id" "uuid" DEFAULT NULL::"uuid", "p_image_id" "uuid" DEFAULT NULL::"uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_message_id uuid;
    v_conversation_id uuid;
BEGIN
    -- Check if a conversation between sender and receiver exists
    IF EXISTS (
        SELECT id
        FROM public.conversations
        WHERE (user_id_a = p_sender_id AND user_id_b = p_receiver_id)
           OR (user_id_a = p_receiver_id AND user_id_b = p_sender_id)
    ) THEN
        -- Conversation exists, get its ID
        SELECT id INTO v_conversation_id
        FROM public.conversations
        WHERE (user_id_a = p_sender_id AND user_id_b = p_receiver_id)
           OR (user_id_a = p_receiver_id AND user_id_b = p_sender_id);
    ELSE
        -- Conversation does not exist, create a new one
        INSERT INTO public.conversations (user_id_a, user_id_b, conversation_type)
        VALUES (p_sender_id, p_receiver_id, 'USER')
        RETURNING id INTO v_conversation_id;
    END IF;

    -- Insert the message
    INSERT INTO public.messages (conversation_id, user_id, context)
    VALUES (v_conversation_id, p_sender_id, p_message_text)
    RETURNING id INTO v_message_id;

    -- Insert attachments if provided
    IF p_file_id IS NOT NULL OR p_image_id IS NOT NULL THEN
        INSERT INTO public.message_attachments (message_id, file_id, image_id)
        VALUES (v_message_id, p_file_id, p_image_id);
    END IF;
END;
$$;

ALTER FUNCTION "public"."create_message_between_users"("p_sender_id" "uuid", "p_receiver_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."create_message_for_event"("p_event_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid" DEFAULT NULL::"uuid", "p_image_id" "uuid" DEFAULT NULL::"uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_message_id uuid;
    v_conversation_id uuid;
BEGIN
    -- Check if a conversation exists for the event
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE event_id = p_event_id;

    -- If a conversation doesn't exist, create one
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (event_id, conversation_type)
        VALUES (p_event_id, 'EVENT')
        RETURNING id INTO v_conversation_id;
    END IF;

    -- Insert the message
    INSERT INTO public.messages (conversation_id, user_id, context)
    VALUES (v_conversation_id, p_user_id, p_message_text)
    RETURNING id INTO v_message_id;

    -- Insert attachments if provided
    IF p_file_id IS NOT NULL OR p_image_id IS NOT NULL THEN
        INSERT INTO public.message_attachments (message_id, file_id, image_id)
        VALUES (v_message_id, p_file_id, p_image_id);
    END IF;
END;
$$;

ALTER FUNCTION "public"."create_message_for_event"("p_event_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."create_message_for_group"("p_group_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid" DEFAULT NULL::"uuid", "p_image_id" "uuid" DEFAULT NULL::"uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_message_id uuid;
    v_conversation_id uuid;
BEGIN
    -- Check if a conversation exists for the group
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE group_id = p_group_id;

    -- If a conversation doesn't exist, create one
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (group_id, conversation_type)
        VALUES (p_group_id, 'GROUP')
        RETURNING id INTO v_conversation_id;
    END IF;

    -- Insert the message
    INSERT INTO public.messages (conversation_id, user_id, context)
    VALUES (v_conversation_id, p_user_id, p_message_text)
    RETURNING id INTO v_message_id;

    -- Insert attachments if provided
    IF p_file_id IS NOT NULL OR p_image_id IS NOT NULL THEN
        INSERT INTO public.message_attachments (message_id, file_id, image_id)
        VALUES (v_message_id, p_file_id, p_image_id);
    END IF;
END;
$$;

ALTER FUNCTION "public"."create_message_for_group"("p_group_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_conversations_for_group"("p_group_id" "uuid") RETURNS TABLE("group_id" "uuid", "group_name" "text", "conversation_id" "uuid", "users_count" bigint, "latest_message_date" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        g.id AS group_id,
        g.group_name,
        c.id AS conversation_id,
        COUNT(DISTINCT u.id)::BIGINT AS users_count,
        MAX(m.created_at) AS latest_message_date -- Remove AT TIME ZONE
    FROM
        public.groups g
    JOIN
        public.conversations c ON g.id = c.group_id
    LEFT JOIN
        public.messages m ON c.id = m.conversation_id
    LEFT JOIN
        public.users_profile u ON m.user_id = u.id
    WHERE
        g.id = p_group_id
        AND c.conversation_type = 'GROUP' -- Add this condition
    GROUP BY
        g.id, g.group_name, c.id;

END;
$$;

ALTER FUNCTION "public"."get_conversations_for_group"("p_group_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_conversations_for_user"("p_user_id" "uuid") RETURNS TABLE("conversation_id" "uuid", "other_user_name" "text", "latest_message" "text", "latest_message_date" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (c.id)
        c.id AS conversation_id,
        CASE
            WHEN c.user_id_a = p_user_id THEN up_b.first_name || ' ' || up_b.last_name
            WHEN c.user_id_b = p_user_id THEN up_a.first_name || ' ' || up_a.last_name
            ELSE 'Unknown'
        END AS other_user_name,
        m.context AS latest_message,
        m.created_at AS latest_message_date
    FROM
        public.conversations c
    LEFT JOIN
        public.messages m ON c.id = m.conversation_id
    LEFT JOIN
        public.users_profile up_a ON c.user_id_a = up_a.id
    LEFT JOIN
        public.users_profile up_b ON c.user_id_b = up_b.id
    WHERE
        (c.user_id_a = p_user_id OR c.user_id_b = p_user_id)
    ORDER BY
        c.id, m.created_at DESC;
END;
$$;

ALTER FUNCTION "public"."get_conversations_for_user"("p_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_events_for_user_in_band"("p_band_id" "uuid", "p_page_number" integer, "p_items_per_page" integer, "p_sort_order" character varying) RETURNS TABLE("event_id" "uuid", "event_name" "text", "description" "text", "event_date" timestamp with time zone, "start_time" time with time zone, "end_time" time with time zone, "creator_user_id" "uuid", "creator_name" "text", "creator_picture" "text", "attendees_count" bigint, "messages_count" bigint, "group_names" "text"[])
    LANGUAGE "plpgsql"
    AS $$
DECLARE
BEGIN
    RETURN QUERY
    SELECT
        e.id AS event_id,
        e.event_name,
        e.description,
        e.event_date,
        e.start_time,
        e.end_time,
        e.creator_user_id,
        up.first_name || ' ' || up.last_name AS creator_name,
        i.image_path::text AS creator_picture,
        COUNT(DISTINCT ea.user_id) AS attendees_count,
        COUNT(DISTINCT m.id) AS messages_count,  -- Count messages by conversation_id
        ARRAY_AGG(DISTINCT g.group_name)::text[] AS group_names
    FROM
        public.events e
    LEFT JOIN
        public.event_attendance ea ON e.id = ea.event_id AND ea.user_id = (SELECT id FROM public.users_profile WHERE auth_user_id = auth.uid())
    LEFT JOIN
        public.users_profile up ON e.creator_user_id = up.id
    LEFT JOIN
        public.images i ON up.profile_image_id = i.id
    LEFT JOIN
        public.conversations c ON e.id = c.event_id
    LEFT JOIN
        public.events_groups eg ON e.id = eg.event_id
    LEFT JOIN
        public.groups g ON eg.group_id = g.id
    LEFT JOIN
        public.messages m ON c.id = m.conversation_id  -- Join messages by conversation_id
    WHERE
        e.band_id = p_band_id
    GROUP BY
        e.id, up.id, c.id, i.id
    ORDER BY
        CASE
            WHEN p_sort_order = 'asc' THEN
                e.event_date
            ELSE
                NULL
        END,
        CASE
            WHEN p_sort_order = 'desc' THEN
                e.event_date
            ELSE
                NULL
        END DESC
    OFFSET
        (p_page_number - 1) * p_items_per_page
    LIMIT
        p_items_per_page;
END;
$$;

ALTER FUNCTION "public"."get_events_for_user_in_band"("p_band_id" "uuid", "p_page_number" integer, "p_items_per_page" integer, "p_sort_order" character varying) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_messages_for_conversation_group"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) RETURNS TABLE("message_id" "uuid", "user_id" "uuid", "user_name" "text", "message" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id AS message_id,
        up.id AS user_id,
        up.first_name || ' ' || up.last_name AS user_name,
        m.context AS message,
        m.created_at
    FROM
        public.messages m
    JOIN
        public.users_profile up ON m.user_id = up.id
    WHERE
        m.conversation_id = p_conversation_id
    ORDER BY
        m.created_at
    OFFSET
        (p_page_number - 1) * p_items_per_page
    LIMIT
        p_items_per_page;
END;
$$;

ALTER FUNCTION "public"."get_messages_for_conversation_group"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_messages_for_conversation_user"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) RETURNS TABLE("message_id" "uuid", "sender_id" "uuid", "sender_name" "text", "message" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id AS message_id,
        m.user_id AS sender_id,
        COALESCE(up.first_name || ' ' || up.last_name, 'Unknown') AS sender_name,
        m.context AS message,
        m.created_at
    FROM
        public.messages m
    LEFT JOIN
        public.users_profile up ON m.user_id = up.id
    JOIN
        public.conversations c ON m.conversation_id = c.id
    WHERE
        m.conversation_id = p_conversation_id
        AND c.conversation_type = 'USER'
        AND c.user_id_a IS NOT NULL AND c.user_id_b IS NOT NULL
    ORDER BY
        m.created_at
    OFFSET
        (p_page_number - 1) * p_items_per_page
    LIMIT
        p_items_per_page;
END;
$$;

ALTER FUNCTION "public"."get_messages_for_conversation_user"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_messages_for_event"("p_event_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) RETURNS TABLE("conversation_id" "uuid", "event_id" "uuid", "message" "text", "sender_user_id" "uuid", "sender_name" "text", "sender_image_path" "text", "file_name" "text", "file_path" "text", "image_name" "text", "image_path" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.event_id,
        m.context AS message,
        m.user_id AS sender_user_id,
        COALESCE(up.first_name || ' ' || up.last_name, 'Unknown') AS sender_name,
        CASE
            WHEN i.image_path IS NOT NULL THEN i.image_path
            ELSE NULL
        END AS sender_image_path,
        f.file_name,
        f.file_path,
        img.image_name,
        img.image_path,
        m.created_at AS timestamp
    FROM
        public.conversations c
    JOIN
        public.messages m ON c.id = m.conversation_id
    LEFT JOIN
        public.users_profile up ON m.user_id = up.id
    LEFT JOIN
        public.images i ON up.profile_image_id = i.id
    LEFT JOIN
        public.message_attachments ma ON m.id = ma.message_id
    LEFT JOIN
        public.files f ON ma.file_id = f.id
    LEFT JOIN
        public.images img ON ma.image_id = img.id
    WHERE
        c.event_id = p_event_id
        AND c.conversation_type = 'EVENT'
    ORDER BY
        m.created_at
    OFFSET
        (p_page_number - 1) * p_items_per_page
    LIMIT
        p_items_per_page;
END;
$$;

ALTER FUNCTION "public"."get_messages_for_event"("p_event_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_single_event_with_details"("p_event_id" "uuid") RETURNS TABLE("event_id" "uuid", "event_name" "text", "description" "text", "event_date" timestamp with time zone, "start_time" time with time zone, "end_time" time with time zone, "creator_user_id" "uuid", "creator_name" "text", "creator_picture" "text", "attendees_count" bigint, "messages_count" bigint, "files" "jsonb"[], "images" "jsonb"[])
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Find the conversation_id for the specified event_id and conversation_type = 'EVENT'
    SELECT
        id
    INTO
        v_conversation_id
    FROM
        public.conversations
    WHERE
        public.conversations.event_id = p_event_id  -- Specify the table alias
        AND conversation_type = 'EVENT'
    LIMIT 1;

    IF v_conversation_id IS NOT NULL THEN
        -- Retrieve event details and related information
        RETURN QUERY
        SELECT
            e.id AS event_id,
            e.event_name,
            e.description,
            e.event_date,
            e.start_time,
            e.end_time,
            e.creator_user_id,
            up.first_name || ' ' || up.last_name AS creator_name,
            i.image_path::text AS creator_picture,
            COUNT(DISTINCT ea.user_id) AS attendees_count,
            COUNT(DISTINCT m.id) AS messages_count,
            ARRAY_AGG(DISTINCT TO_JSONB(f.file_path)) AS files,
            ARRAY_AGG(DISTINCT TO_JSONB(im.image_path)) AS images
        FROM
            public.events e
        LEFT JOIN
            public.event_attendance ea ON e.id = ea.event_id
        LEFT JOIN
            public.users_profile up ON e.creator_user_id = up.id
        LEFT JOIN
            public.images i ON up.profile_image_id = i.id
        LEFT JOIN
            public.messages m ON v_conversation_id = m.conversation_id
        LEFT JOIN
            public.events_files ef ON e.id = ef.event_id
        LEFT JOIN
            public.files f ON ef.file_id = f.id
        LEFT JOIN
            public.events_images ei ON e.id = ei.event_id
        LEFT JOIN
            public.images im ON ei.image_id = im.id
        WHERE
            e.id = p_event_id
        GROUP BY
            e.id, e.event_name, e.description, e.event_date, e.start_time, e.end_time,
            e.creator_user_id, up.first_name, up.last_name, i.image_path::text;

    END IF;
END;
$$;

ALTER FUNCTION "public"."get_single_event_with_details"("p_event_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_users_for_event"("p_event_id" "uuid") RETURNS TABLE("user_id" "uuid", "full_name" "text", "image_path" "text", "attendance_status" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        up.id AS user_id,
        up.first_name || ' ' || up.last_name AS full_name,
        i.image_path,
        COALESCE(ea.status::text, 'NOT_ATTENDING') AS attendance_status
    FROM
        public.users_profile up
    JOIN
        public.event_attendance ea ON up.id = ea.user_id AND ea.event_id = p_event_id
    LEFT JOIN
        public.images i ON up.profile_image_id = i.id;
END;
$$;

ALTER FUNCTION "public"."get_users_for_event"("p_event_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Insert a new user with status as 'ACTIVE'
  INSERT INTO public.users_profile (auth_user_id, email, status)
  VALUES (NEW.id, NEW.email, 'ACTIVE');
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_removed_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Check if the user exists in the users_profile table
  IF EXISTS (SELECT 1 FROM public.users_profile WHERE auth_user_id = OLD.id) THEN
    -- Set status to 'DEACTIVATED' and remove auth_user_id before the user is deleted
    UPDATE public.users_profile
    SET status = 'DEACTIVATED',
        auth_user_id = NULL
    WHERE auth_user_id = OLD.id;

    -- Perform other actions as needed
  END IF;

  RETURN OLD;
END;
$$;

ALTER FUNCTION "public"."handle_removed_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."bands" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "band_image_id" "uuid"
);

ALTER TABLE "public"."bands" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "band_id" "uuid",
    "event_id" "uuid",
    "group_id" "uuid",
    "user_id_a" "uuid",
    "user_id_b" "uuid",
    "conversation_type" "public"."conversation_type" NOT NULL
);

ALTER TABLE "public"."conversations" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."event_attendance" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" "public"."attendence_status" DEFAULT 'ATTENDING'::"public"."attendence_status" NOT NULL,
    "event_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL
);

ALTER TABLE "public"."event_attendance" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."events" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "event_name" "text" NOT NULL,
    "description" "text",
    "event_date" timestamp with time zone,
    "start_time" time with time zone,
    "end_time" time with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "band_id" "uuid" NOT NULL,
    "creator_user_id" "uuid" NOT NULL,
    "owner_user_id" "uuid"
);

ALTER TABLE "public"."events" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."events_files" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "file_id" "uuid" NOT NULL
);

ALTER TABLE "public"."events_files" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."events_groups" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "group_id" "uuid" NOT NULL
);

ALTER TABLE "public"."events_groups" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."events_images" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "image_id" "uuid" NOT NULL
);

ALTER TABLE "public"."events_images" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."files" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "file_name" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."files" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."groups" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "group_name" "text" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "band_id" "uuid" NOT NULL
);

ALTER TABLE "public"."groups" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."images" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "image_name" "text",
    "image_path" "text" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."images" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."message_attachments" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "file_id" "uuid",
    "image_id" "uuid",
    "message_id" "uuid" NOT NULL
);

ALTER TABLE "public"."message_attachments" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."message_read_status" (
    "user_id" "uuid" NOT NULL,
    "message_id" "uuid" NOT NULL,
    "is_read" boolean DEFAULT false
);

ALTER TABLE "public"."message_read_status" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."messages" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "context" "text" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid",
    "user_id" "uuid" NOT NULL
);

ALTER TABLE "public"."messages" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."users_bands" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "band_id" "uuid" NOT NULL
);

ALTER TABLE "public"."users_bands" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."users_groups" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL
);

ALTER TABLE "public"."users_groups" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."users_profile" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "auth_user_id" "uuid",
    "email" character varying,
    "phone" "text",
    "profile_image_id" "uuid",
    "status" "public"."user_status" DEFAULT 'ACTIVE'::"public"."user_status" NOT NULL,
    "first_name" "text",
    "last_name" "text",
    "is_child" boolean DEFAULT false NOT NULL,
    "child_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "about" "text",
    "instruments" "text"[],
    "title" "text"
);

ALTER TABLE "public"."users_profile" OWNER TO "postgres";

ALTER TABLE ONLY "public"."bands"
    ADD CONSTRAINT "Bands_name_key" UNIQUE ("name");

ALTER TABLE ONLY "public"."bands"
    ADD CONSTRAINT "Bands_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "Conversations_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "Events_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."files"
    ADD CONSTRAINT "Files_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "Groups_group_name_key" UNIQUE ("group_name");

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "Groups_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."images"
    ADD CONSTRAINT "Images_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."message_attachments"
    ADD CONSTRAINT "Message_Attachments_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "Messages_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."event_attendance"
    ADD CONSTRAINT "event_attendance_pkey" PRIMARY KEY ("event_id", "user_id");

ALTER TABLE ONLY "public"."events_files"
    ADD CONSTRAINT "events_files_pkey" PRIMARY KEY ("event_id", "file_id");

ALTER TABLE ONLY "public"."events_groups"
    ADD CONSTRAINT "events_groups_pkey" PRIMARY KEY ("event_id", "group_id");

ALTER TABLE ONLY "public"."events_images"
    ADD CONSTRAINT "events_images_pkey" PRIMARY KEY ("event_id", "image_id");

ALTER TABLE ONLY "public"."message_read_status"
    ADD CONSTRAINT "message_read_status_pkey" PRIMARY KEY ("user_id", "message_id");

ALTER TABLE ONLY "public"."users_bands"
    ADD CONSTRAINT "users_bands_pkey" PRIMARY KEY ("user_id", "band_id");

ALTER TABLE ONLY "public"."users_groups"
    ADD CONSTRAINT "users_groups_pkey" PRIMARY KEY ("group_id", "user_id");

ALTER TABLE ONLY "public"."users_profile"
    ADD CONSTRAINT "users_profile_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."bands"
    ADD CONSTRAINT "bands_band_image_id_fkey" FOREIGN KEY ("band_image_id") REFERENCES "public"."images"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_band_id_fkey" FOREIGN KEY ("band_id") REFERENCES "public"."bands"("id");

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id");

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id");

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_user_id_a_fkey" FOREIGN KEY ("user_id_a") REFERENCES "public"."users_profile"("id");

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_user_id_b_fkey" FOREIGN KEY ("user_id_b") REFERENCES "public"."users_profile"("id");

ALTER TABLE ONLY "public"."event_attendance"
    ADD CONSTRAINT "event_attendance_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."event_attendance"
    ADD CONSTRAINT "event_attendance_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_band_id_fkey" FOREIGN KEY ("band_id") REFERENCES "public"."bands"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_creator_user_id_fkey" FOREIGN KEY ("creator_user_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events_files"
    ADD CONSTRAINT "events_files_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events_files"
    ADD CONSTRAINT "events_files_file_id_fkey" FOREIGN KEY ("file_id") REFERENCES "public"."files"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events_groups"
    ADD CONSTRAINT "events_groups_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events_groups"
    ADD CONSTRAINT "events_groups_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events_images"
    ADD CONSTRAINT "events_images_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events_images"
    ADD CONSTRAINT "events_images_image_id_fkey" FOREIGN KEY ("image_id") REFERENCES "public"."images"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_band_id_fkey" FOREIGN KEY ("band_id") REFERENCES "public"."bands"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."message_attachments"
    ADD CONSTRAINT "message_attachments_file_id_fkey" FOREIGN KEY ("file_id") REFERENCES "public"."files"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."message_attachments"
    ADD CONSTRAINT "message_attachments_image_id_fkey" FOREIGN KEY ("image_id") REFERENCES "public"."images"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."message_attachments"
    ADD CONSTRAINT "message_attachments_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."messages"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."message_read_status"
    ADD CONSTRAINT "message_read_status_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."messages"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."message_read_status"
    ADD CONSTRAINT "message_read_status_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."users_bands"
    ADD CONSTRAINT "users_bands_band_id_fkey" FOREIGN KEY ("band_id") REFERENCES "public"."bands"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."users_bands"
    ADD CONSTRAINT "users_bands_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."users_groups"
    ADD CONSTRAINT "users_groups_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."users_groups"
    ADD CONSTRAINT "users_groups_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."users_profile"
    ADD CONSTRAINT "users_profile_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."users_profile"
    ADD CONSTRAINT "users_profile_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "public"."users_profile"("id") ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY "public"."users_profile"
    ADD CONSTRAINT "users_profile_profile_image_id_fkey" FOREIGN KEY ("profile_image_id") REFERENCES "public"."images"("id") ON UPDATE CASCADE ON DELETE CASCADE;

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."create_message_between_users"("p_sender_id" "uuid", "p_receiver_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_message_between_users"("p_sender_id" "uuid", "p_receiver_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_message_between_users"("p_sender_id" "uuid", "p_receiver_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."create_message_for_event"("p_event_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_message_for_event"("p_event_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_message_for_event"("p_event_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."create_message_for_group"("p_group_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_message_for_group"("p_group_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_message_for_group"("p_group_id" "uuid", "p_user_id" "uuid", "p_message_text" "text", "p_file_id" "uuid", "p_image_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_conversations_for_group"("p_group_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_conversations_for_group"("p_group_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_conversations_for_group"("p_group_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_conversations_for_user"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_conversations_for_user"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_conversations_for_user"("p_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_events_for_user_in_band"("p_band_id" "uuid", "p_page_number" integer, "p_items_per_page" integer, "p_sort_order" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."get_events_for_user_in_band"("p_band_id" "uuid", "p_page_number" integer, "p_items_per_page" integer, "p_sort_order" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_events_for_user_in_band"("p_band_id" "uuid", "p_page_number" integer, "p_items_per_page" integer, "p_sort_order" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_messages_for_conversation_group"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_messages_for_conversation_group"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_messages_for_conversation_group"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_messages_for_conversation_user"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_messages_for_conversation_user"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_messages_for_conversation_user"("p_conversation_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_messages_for_event"("p_event_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_messages_for_event"("p_event_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_messages_for_event"("p_event_id" "uuid", "p_page_number" integer, "p_items_per_page" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_single_event_with_details"("p_event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_single_event_with_details"("p_event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_single_event_with_details"("p_event_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_users_for_event"("p_event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_users_for_event"("p_event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_users_for_event"("p_event_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_removed_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_removed_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_removed_user"() TO "service_role";

GRANT ALL ON TABLE "public"."bands" TO "anon";
GRANT ALL ON TABLE "public"."bands" TO "authenticated";
GRANT ALL ON TABLE "public"."bands" TO "service_role";

GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";

GRANT ALL ON TABLE "public"."event_attendance" TO "anon";
GRANT ALL ON TABLE "public"."event_attendance" TO "authenticated";
GRANT ALL ON TABLE "public"."event_attendance" TO "service_role";

GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";

GRANT ALL ON TABLE "public"."events_files" TO "anon";
GRANT ALL ON TABLE "public"."events_files" TO "authenticated";
GRANT ALL ON TABLE "public"."events_files" TO "service_role";

GRANT ALL ON TABLE "public"."events_groups" TO "anon";
GRANT ALL ON TABLE "public"."events_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."events_groups" TO "service_role";

GRANT ALL ON TABLE "public"."events_images" TO "anon";
GRANT ALL ON TABLE "public"."events_images" TO "authenticated";
GRANT ALL ON TABLE "public"."events_images" TO "service_role";

GRANT ALL ON TABLE "public"."files" TO "anon";
GRANT ALL ON TABLE "public"."files" TO "authenticated";
GRANT ALL ON TABLE "public"."files" TO "service_role";

GRANT ALL ON TABLE "public"."groups" TO "anon";
GRANT ALL ON TABLE "public"."groups" TO "authenticated";
GRANT ALL ON TABLE "public"."groups" TO "service_role";

GRANT ALL ON TABLE "public"."images" TO "anon";
GRANT ALL ON TABLE "public"."images" TO "authenticated";
GRANT ALL ON TABLE "public"."images" TO "service_role";

GRANT ALL ON TABLE "public"."message_attachments" TO "anon";
GRANT ALL ON TABLE "public"."message_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."message_attachments" TO "service_role";

GRANT ALL ON TABLE "public"."message_read_status" TO "anon";
GRANT ALL ON TABLE "public"."message_read_status" TO "authenticated";
GRANT ALL ON TABLE "public"."message_read_status" TO "service_role";

GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";

GRANT ALL ON TABLE "public"."users_bands" TO "anon";
GRANT ALL ON TABLE "public"."users_bands" TO "authenticated";
GRANT ALL ON TABLE "public"."users_bands" TO "service_role";

GRANT ALL ON TABLE "public"."users_groups" TO "anon";
GRANT ALL ON TABLE "public"."users_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."users_groups" TO "service_role";

GRANT ALL ON TABLE "public"."users_profile" TO "anon";
GRANT ALL ON TABLE "public"."users_profile" TO "authenticated";
GRANT ALL ON TABLE "public"."users_profile" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
