-- supabase/seed.sql
--
-- create test users
INSERT INTO
    auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) (
        select
            '00000000-0000-0000-0000-000000000000',
            uuid_generate_v4 (),
            'authenticated',
            'authenticated',
            'user' || (ROW_NUMBER() OVER ()) || '@example.com',
            crypt ('password123', gen_salt ('bf')),
            current_timestamp,
            current_timestamp,
            current_timestamp,
            '{"provider":"email","providers":["email"]}',
            '{}',
            current_timestamp,
            current_timestamp,
            '',
            '',
            '',
            ''
        FROM
            generate_series(1, 4)
    );

-- test user email identities
INSERT INTO
    auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    ) (
        select
            uuid_generate_v4 (),
            id,
            format('{"sub":"%s","email":"%s"}', id::text, email)::jsonb,
            'email',
            current_timestamp,
            current_timestamp,
            current_timestamp
        from
            auth.users
    );

-- Seed data for "users_profile" table
INSERT INTO public.users_profile (id, auth_user_id, email, phone, profile_image_id, status, first_name, last_name, is_child, created_at, about, instruments, title)
VALUES 
  (uuid_generate_v4(), (SELECT id FROM auth.users WHERE email = 'user1@example.com'), 'user1@example.com', '+1234567890', NULL, 'ACTIVE', 'John', 'Doe', false, NOW(), 'Music enthusiast', ARRAY['Guitar', 'Piano'], 'Musician'),
  (uuid_generate_v4(), (SELECT id FROM auth.users WHERE email = 'user2@example.com'), 'user2@example.com', '+9876543210', NULL, 'ACTIVE', 'Jane', 'Smith', false, NOW(), 'Bass player', ARRAY['Bass Guitar'], 'Musician'),
  (uuid_generate_v4(), (SELECT id FROM auth.users WHERE email = 'user3@example.com'), 'user3@example.com', '+1234567890', NULL, 'ACTIVE', 'Bob', 'Bobby', true, NOW(), 'Rock on with ya bad self.', ARRAY['Baratone', 'Saxaphone'], 'The Best of the rest'),
  (uuid_generate_v4(), (SELECT id FROM auth.users WHERE email = 'user4@example.com'), 'user4@example.com', '+9876543210', NULL, 'ACTIVE', 'Sue', 'Suzzy', true, NOW(), 'I am awesome and amazing and rockin!', ARRAY['Colorguard'], 'Senior colorguard');

-- Seed data for "parent_child_relationship" table
INSERT INTO public.parent_child_relationship (parent_id, child_id, created_at)
VALUES
    ((SELECT id FROM public.users_profile WHERE email = 'user1@example.com'), (SELECT id FROM public.users_profile WHERE email = 'user3@example.com'), NOW()),
    ((SELECT id FROM public.users_profile WHERE email = 'user1@example.com'), (SELECT id FROM public.users_profile WHERE email = 'user4@example.com'), NOW());


-- Seed data for "bands" table
INSERT INTO public.bands (id, created_at, name, description, band_image_id)
VALUES
    (uuid_generate_v4(), NOW(), 'XYZ High School', 'Talented musicians from XYZ High School', NULL),
    (uuid_generate_v4(), NOW(), 'ABC High School', 'Jazz ensemble with a passion for music', NULL);

-- Seed data for "users_bands" table
INSERT INTO public.users_bands (user_id, band_id, created_at)
SELECT
    u.id,
    b.id,
    NOW()
FROM public.users_profile u
CROSS JOIN public.bands b;

-- Seed data for "events" table
INSERT INTO public.events (id, created_at, event_name, description, event_date, start_time, end_time, band_id, creator_user_id, owner_user_id, event_type, about, location_name)
VALUES
    (uuid_generate_v4(), NOW(), 'High School Concert', 'Annual concert showcasing our talented students', NOW() + '5 days', NOW() + '5 days', NOW() + '3 hours', (SELECT id FROM public.bands LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1), 'Practice', 'This is the information about this event.', 'School Gym'),
    (uuid_generate_v4(), NOW(), 'Jazz Night', 'An evening filled with smooth jazz melodies', NOW() + '10 days', NOW() + '10 days', NOW() + '6 hours', (SELECT id FROM public.bands LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1), 'Performance', 'More information about this event that you can use.', 'Football Field'),
    (uuid_generate_v4(), NOW(), 'Rock Fest', 'A high-energy rock concert featuring local bands', NOW() + '45 days', NOW() + '45 days', NOW() + '10 hours', (SELECT id FROM public.bands LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1), 'Training', 'This is a great event! Come join us and be there.', 'School Gym');

-- Seed data for "groups" table
INSERT INTO public.groups (id, created_at, group_name, band_id)
VALUES
    (uuid_generate_v4(), NOW(), 'Jazz Ensemble', (SELECT id FROM public.bands LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'Rock Band', (SELECT id FROM public.bands LIMIT 1));

-- Seed data for "users_groups" table
INSERT INTO public.users_groups (group_id, user_id, created_at)
SELECT
    g.id,
    u.id,
    NOW()
FROM public.groups g
JOIN public.users_profile u ON true;

-- Seed data for "conversations" table
INSERT INTO public.conversations (id, created_at, band_id, event_id, group_id, user_id_a, user_id_b, conversation_type)
VALUES
    (uuid_generate_v4(), NOW(), NULL, NULL, NULL, (SELECT id FROM public.users_profile LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1), 'USER'),
    (uuid_generate_v4(), NOW(), NULL, (SELECT id FROM public.events LIMIT 1), NULL, NULL, NULL, 'EVENT'),
    (uuid_generate_v4(), NOW(), NULL, NULL, (SELECT id FROM public.groups LIMIT 1), NULL, NULL, 'GROUP');

-- Seed data for "images" table
INSERT INTO public.images (id, created_at, image_name, image_path)
VALUES
    (uuid_generate_v4(), NOW(), 'ConcertImage1.jpg', '/images/concert_image1.jpg');

-- Seed data for "messages" table
INSERT INTO public.messages (id, created_at, context, conversation_id, user_id)
VALUES
    (uuid_generate_v4(), NOW(), 'Hey, we can practice for the upcoming concert!', (SELECT id FROM public.conversations WHERE conversation_type = 'USER' LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'Sure, I am available tomorrow afternoon.', (SELECT id FROM public.conversations WHERE conversation_type = 'USER' LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'Great! We can meet at the practice room.', (SELECT id FROM public.conversations WHERE conversation_type = 'USER' LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'Hello everyone! Do not forget about the Jazz Night rehearsal.', (SELECT id FROM public.conversations WHERE conversation_type = 'GROUP' LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'See you all there!', (SELECT id FROM public.conversations WHERE conversation_type = 'GROUP' LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'Welcome to our group everyone!', (SELECT id FROM public.conversations WHERE conversation_type = 'GROUP' LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'Hello!', (SELECT id FROM public.conversations WHERE conversation_type = 'GROUP' LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1)),
    (uuid_generate_v4(), NOW(), 'YOOOO', (SELECT id FROM public.conversations WHERE conversation_type = 'GROUP' LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1));

-- Seed data for "events_groups" table
INSERT INTO public.events_groups (created_at, event_id, group_id)
VALUES
    (NOW(), (SELECT id FROM public.events LIMIT 1), (SELECT id FROM public.groups LIMIT 1)),
    (NOW(), (SELECT id FROM public.events OFFSET 1 LIMIT 1), (SELECT id FROM public.groups OFFSET 1 LIMIT 1));

-- Seed data for "events_images" table
INSERT INTO public.events_images (created_at, event_id, image_id)
VALUES
    (NOW(), (SELECT id FROM public.events LIMIT 1), (SELECT id FROM public.images LIMIT 1));

-- Seed data for "event_attendance" table
INSERT INTO public.event_attendance (created_at, status, event_id, user_id)
VALUES
    (NOW(), 'ATTENDING', (SELECT id FROM public.events LIMIT 1), (SELECT id FROM public.users_profile LIMIT 1)),
    (NOW(), 'NOT_ATTENDING', (SELECT id FROM public.events LIMIT 1), (SELECT id FROM public.users_profile OFFSET 1 LIMIT 1));

-- Seed data for "files" table
INSERT INTO public.files (id, created_at, file_name, file_path)
VALUES
    (uuid_generate_v4(), NOW(), 'SampleFile1.pdf', '/files/sample1.pdf'),
    (uuid_generate_v4(), NOW(), 'SampleFile2.docx', '/files/sample2.docx');

-- Seed data for "events_files" table
INSERT INTO public.events_files (created_at, event_id, file_id)
VALUES
    (NOW(), (SELECT id FROM public.events LIMIT 1), (SELECT id FROM public.files LIMIT 1)),
    (NOW(), (SELECT id FROM public.events LIMIT 1), (SELECT id FROM public.files OFFSET 1 LIMIT 1));

-- Seed data for "message_attachments" table
INSERT INTO public.message_attachments (created_at, file_id, image_id, message_id)
VALUES
    (NOW(), (SELECT id FROM public.files LIMIT 1), NULL, (SELECT id FROM public.messages WHERE conversation_id IS NOT NULL LIMIT 1)),
    (NOW(), NULL, (SELECT id FROM public.images LIMIT 1), (SELECT id FROM public.messages WHERE conversation_id IS NOT NULL LIMIT 1));

-- Seed data for "message_read_status" table
INSERT INTO public.message_read_status (user_id, message_id, is_read)
VALUES
    ((SELECT id FROM public.users_profile LIMIT 1), (SELECT id FROM public.messages WHERE conversation_id IS NOT NULL LIMIT 1), true),
    ((SELECT id FROM public.users_profile OFFSET 1 LIMIT 1), (SELECT id FROM public.messages WHERE conversation_id IS NOT NULL LIMIT 1), false),
    ((SELECT id FROM public.users_profile LIMIT 1), (SELECT id FROM public.messages WHERE conversation_id IS NOT NULL OFFSET 1 LIMIT 1), true);




