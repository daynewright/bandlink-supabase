-- Step 1: Drop the existing function
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_events_for_user_in_band') THEN
        DROP FUNCTION public.get_events_for_user_in_band(uuid, integer, integer, character varying);
    END IF;
END $$;

-- Step 2: Create the updated function
CREATE OR REPLACE FUNCTION public.get_events_for_user_in_band(
    p_band_id "uuid", 
    p_page_number integer, 
    p_items_per_page integer, 
    p_sort_order character varying
) RETURNS TABLE(
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
    "group_names" "text"[]
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
