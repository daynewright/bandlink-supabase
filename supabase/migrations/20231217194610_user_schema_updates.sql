CREATE TABLE IF NOT EXISTS "public"."parent_child_relationship" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "parent_id" "uuid" REFERENCES "public"."users_profile"("id"),
    "child_id" "uuid" REFERENCES "public"."users_profile"("id"),
    PRIMARY KEY ("parent_id", "child_id")
);

DROP FUNCTION IF EXISTS "public"."get_events_for_user_in_band"("uuid", integer, integer, character varying);
CREATE OR REPLACE FUNCTION "public"."get_events_for_user_in_band"(
    "p_band_id" "uuid",
    "p_user_id" "uuid", -- Added user_id parameter
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
        public.event_attendance ea ON e.id = ea.event_id
    LEFT JOIN
        public.users_profile up ON e.creator_user_id = up.id
    LEFT JOIN
        public.images i ON up.profile_image_id = i.id
    LEFT JOIN
        public.users_bands ub ON e.band_id = ub.band_id AND ub.user_id = p_user_id -- Check if user is in the band
    LEFT JOIN
        public.users_groups ug ON p_user_id = ug.user_id
    LEFT JOIN
        public.groups g ON ug.group_id = g.id
    LEFT JOIN
        public.events_groups eg ON e.id = eg.event_id AND eg.group_id = g.id -- Check if event is associated with the user's group
    LEFT JOIN
        public.messages m ON e.id = m.conversation_id -- Consider only messages related to the event
    WHERE
        e.band_id = p_band_id
        AND ub.user_id IS NOT NULL -- Ensure user is in the band
        AND ug.group_id IS NOT NULL -- Ensure user is in a group
        AND eg.event_id IS NOT NULL -- Ensure event is associated with a group
    GROUP BY
        e.id, up.id, i.image_path -- Include i.image_path in the GROUP BY clause
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



