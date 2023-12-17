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
    messages_count BIGINT
)
AS $$
BEGIN
    RETURN QUERY
    WITH pgrst_source AS (
        -- Find the conversation_id for the specified event_id and conversation_type = 'EVENT'
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
        COALESCE(mc.messages_count, 0) AS messages_count
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
        mc.messages_count;

END;
$$ LANGUAGE plpgsql;






