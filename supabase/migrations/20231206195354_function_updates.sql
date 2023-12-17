ALTER TABLE public.events
ADD COLUMN event_type TEXT,
ADD COLUMN location_name TEXT,
ADD COLUMN location_address TEXT,
ADD COLUMN about TEXT,
ADD COLUMN location_lat DOUBLE PRECISION,
ADD COLUMN location_lng DOUBLE PRECISION;

-- Update get_single_event_with_details to return additional data
DROP FUNCTION IF EXISTS get_single_event_with_details(p_event_id UUID);

CREATE OR REPLACE FUNCTION public.get_single_event_with_details(
    p_event_id UUID
)
RETURNS TABLE (
    event_id UUID,
    event_name TEXT,
    description TEXT,
    event_date timestamp with time zone,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    creator_user_id UUID,
    creator_name TEXT,
    creator_picture TEXT,
    attendees_count BIGINT,
    attendees JSONB,
    files JSONB,
    images JSONB,
    messages_count BIGINT,
    event_type TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    about TEXT,
    location_address TEXT,
    location_name TEXT
)
AS $$
BEGIN
    RETURN QUERY
    WITH pgrst_source AS (
        SELECT
            id
        FROM
            public.conversations
        WHERE
            public.conversations.event_id = p_event_id
            AND conversation_type = 'EVENT'
        LIMIT 1
    )
    SELECT
        e.id AS event_id,
        e.event_name,
        e.description,
        e.event_date,
        e.start_time,
        e.end_time,
        e.creator_user_id,
        COALESCE(up_creator.first_name || ' ' || up_creator.last_name, '') AS creator_name,
        COALESCE(i.image_path::TEXT, '') AS creator_picture,
        COUNT(DISTINCT ea.user_id) AS attendees_count,
        CASE
            WHEN COUNT(DISTINCT ea.user_id) > 0 THEN
                jsonb_agg(DISTINCT jsonb_build_object(
                    'id', up_attendee.id,
                    'name', COALESCE(up_attendee.first_name || ' ' || up_attendee.last_name, ''),
                    'avatar', COALESCE(ui.image_path::TEXT, ''),
                    'initials', COALESCE(substr(up_attendee.first_name, 1, 1) || substr(up_attendee.last_name, 1, 1), '')
                ))
            ELSE '[]'::JSONB
        END AS attendees,
        CASE
            WHEN COUNT(DISTINCT ef.file_id) > 0 THEN
                jsonb_agg(DISTINCT jsonb_build_object(
                    'id', ef.file_id,
                    'url', COALESCE(f.file_path, ''),
                    'name', COALESCE(f.file_name, '')
                ))
            ELSE '[]'::JSONB
        END AS files,
        CASE
            WHEN COUNT(DISTINCT ei.image_id) > 0 THEN
                jsonb_agg(DISTINCT jsonb_build_object(
                    'id', ei.image_id,
                    'url', COALESCE(im.image_path, ''),
                    'name', COALESCE(im.image_name, '')
                ))
            ELSE '[]'::JSONB
        END AS images,
        COALESCE(mc.messages_count, 0) AS messages_count,
        e.event_type,
        e.location_lat,
        e.location_lng,
        e.about,
        e.location_address,
        e.location_name
    FROM
        public.events e
    LEFT JOIN
        public.event_attendance ea ON e.id = ea.event_id
    LEFT JOIN
        public.users_profile up_creator ON e.creator_user_id = up_creator.id
    LEFT JOIN
        public.images i ON up_creator.profile_image_id = i.id
    LEFT JOIN
        public.conversations c ON e.id = c.event_id
    LEFT JOIN
        public.messages m ON c.id = m.conversation_id
    LEFT JOIN
        public.users_profile up_attendee ON ea.user_id = up_attendee.id
    LEFT JOIN
        public.images ui ON up_attendee.profile_image_id = ui.id
    LEFT JOIN
        public.events_files ef ON e.id = ef.event_id
    LEFT JOIN
        public.files f ON ef.file_id = f.id
    LEFT JOIN
        public.events_images ei ON e.id = ei.event_id
    LEFT JOIN
        public.images im ON ei.image_id = im.id
    LEFT JOIN (
        SELECT
            conversation_id,
            COUNT(*) AS messages_count
        FROM
            public.messages
        GROUP BY
            conversation_id
    ) mc ON c.id = mc.conversation_id
    WHERE
        e.id = p_event_id
    GROUP BY
        e.id,
        e.event_name,
        e.description,
        e.event_date,
        e.start_time,
        e.end_time,
        e.creator_user_id,
        up_creator.first_name,
        up_creator.last_name,
        i.image_path::TEXT,
        mc.messages_count,
        e.event_type,
        e.location_lat,
        e.location_lng,
        e.about,
        e.location_address;

END;
$$ LANGUAGE plpgsql;

-- Update get_events_for_user_in_band to return additional events data
DROP FUNCTION IF EXISTS get_events_for_user_in_band(
    "p_band_id" "uuid",
    "p_page_number" integer,
    "p_items_per_page" integer,
    "p_sort_order" character varying);

CREATE OR REPLACE FUNCTION public.get_events_for_user_in_band(
    "p_band_id" "uuid",
    "p_page_number" integer,
    "p_items_per_page" integer,
    "p_sort_order" character varying
) RETURNS TABLE (
    "event_id" "uuid",
    "event_name" "text",
    "description" "text",
    "event_date" timestamp with time zone,
    "start_time" timestamp with time zone,
    "end_time" timestamp with time zone,
    "creator_user_id" "uuid",
    "creator_name" "text",
    "creator_picture" "text",
    "attendees_count" bigint,
    "messages_count" bigint,
    "group_names" "text"[],
    "event_type" "text", -- Add new columns
    "location_lat" double precision,
    "location_lng" double precision,
    "about" "text",
    "location_address" "text",
    "location_name" "text"
) LANGUAGE "plpgsql" AS $$
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
        COUNT(DISTINCT m.id) AS messages_count,
        ARRAY_AGG(DISTINCT g.group_name)::text[] AS group_names,
        -- Add new columns
        e.event_type,
        e.location_lat,
        e.location_lng,
        e.about,
        e.location_address,
        e.location_name
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
        public.messages m ON c.id = m.conversation_id
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

-- Get conversation groups by user id
CREATE OR REPLACE FUNCTION public.get_group_conversations_by_user_id(
    "p_user_id" "uuid"
) RETURNS TABLE (
    "group_id" "uuid",
    "group_name" "text",
    "conversation_id" "uuid",
    "users_count" bigint,
    "latest_message_date" timestamp with time zone
) LANGUAGE "plpgsql" AS $$
BEGIN
    RETURN QUERY
    SELECT
        g.id AS group_id,
        g.group_name,
        c.id AS conversation_id,
        COUNT(DISTINCT ug.user_id) AS users_count,
        MAX(m.created_at) AS latest_message_date
    FROM
        public.groups g
    LEFT JOIN
        public.users_groups ug ON g.id = ug.group_id
    LEFT JOIN
        public.conversations c ON g.id = c.group_id AND c.conversation_type = 'GROUP'
    LEFT JOIN
        public.messages m ON c.id = m.conversation_id
    WHERE
        g.id = ug.group_id
    GROUP BY
        g.id, g.group_name, c.id;

END;
$$;

-- Drop the function if it exists
DROP FUNCTION IF EXISTS "public"."get_messages_for_event"(
  "p_event_id" uuid,
  "p_page_number" integer,
  "p_items_per_page" integer
);

-- Recreate the function with the updated order
CREATE OR REPLACE FUNCTION "public"."get_messages_for_event"(
  "p_event_id" uuid,
  "p_page_number" integer,
  "p_items_per_page" integer
) RETURNS TABLE(
  "conversation_id" uuid,
  "event_id" uuid,
  "message" text,
  "sender_user_id" uuid,
  "sender_name" text,
  "sender_image_path" text,
  "file_name" text,
  "file_path" text,
  "image_name" text,
  "image_path" text,
  "created_at" timestamp with time zone
)
LANGUAGE "plpgsql" AS $$
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
        m.created_at ASC -- Sort in ascending order
    OFFSET
        (p_page_number - 1) * p_items_per_page
    LIMIT
        p_items_per_page;
END;
$$;

-- Create a unique constraint on event_id
ALTER TABLE public.conversations
ADD CONSTRAINT conversations_event_id_unique UNIQUE (event_id);

-- Create a unique constraint on group_id
ALTER TABLE public.conversations
ADD CONSTRAINT conversations_group_id_unique UNIQUE (group_id);

-- Create a check constraint to require event_id when conversation_type is 'EVENT'
ALTER TABLE public.conversations
ADD CONSTRAINT conversations_event_id_required
CHECK (
    (conversation_type = 'EVENT' AND event_id IS NOT NULL)
    OR (conversation_type <> 'EVENT')
);

-- Create a check constraint to require group_id when conversation_type is 'GROUP'
ALTER TABLE public.conversations
ADD CONSTRAINT conversations_group_id_required
CHECK (
    (conversation_type = 'GROUP' AND group_id IS NOT NULL)
    OR (conversation_type <> 'GROUP')
);

-- Create a check constraint to require user_id_a and user_id_b when conversation_type is 'USER'
ALTER TABLE public.conversations
ADD CONSTRAINT conversations_user_ids_required
CHECK (
    (conversation_type = 'USER' AND user_id_a IS NOT NULL AND user_id_b IS NOT NULL)
    OR (conversation_type <> 'USER')
);


-- Update to only return groups that have an active conversation created
DROP FUNCTION IF EXISTS "public"."get_group_conversations_by_user_id"("uuid");

CREATE OR REPLACE FUNCTION public.get_group_conversations_by_user_id(
    p_user_id uuid
) RETURNS TABLE (
    group_id uuid,
    group_name text,
    conversation_id uuid,
    users_count bigint,
    latest_message_date timestamp with time zone
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        g.id AS group_id,
        g.group_name,
        c.id AS conversation_id,
        (
            SELECT COUNT(DISTINCT ug_sub.user_id)
            FROM public.users_groups ug_sub
            WHERE ug_sub.group_id = g.id
        ) AS users_count,
        MAX(m.created_at) AS latest_message_date
    FROM
        public.groups g
    JOIN
        public.conversations c ON g.id = c.group_id AND c.conversation_type = 'GROUP'
    JOIN
        public.users_groups ug ON g.id = ug.group_id
    LEFT JOIN
        public.messages m ON c.id = m.conversation_id
    WHERE
        ug.user_id = p_user_id
        AND c.id IS NOT NULL -- Ensure there is a conversation_id
    GROUP BY
        g.id, g.group_name, c.id;

END;
$$;


























