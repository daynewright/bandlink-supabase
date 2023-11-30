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
            generate_series(1, 10)
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


-- Seed data for "bands" table
INSERT INTO public.bands (id, created_at, name, description, band_image_id)
VALUES 
  ('b63df5e0-9f5f-420e-a6d7-7c96c03f8724', NOW(), 'XYZ High School', 'Talented musicians from XYZ High School', NULL),
  ('b56d3c61-8e5b-4c3a-b8b9-1c2f71d3e0f1', NOW(), 'ABC High School', 'Jazz ensemble with a passion for music', NULL);

-- Seed data for "users_profile" table
INSERT INTO public.users_profile (id, auth_user_id, email, phone, profile_image_id, status, first_name, last_name, is_child, child_id, created_at, about, instruments, title)
VALUES 
  ('8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', (SELECT id FROM auth.users WHERE email = 'user1@example.com'), 'user1@example.com', '+1234567890', NULL, 'ACTIVE', 'John', 'Doe', false, NULL, NOW(), 'Music enthusiast', ARRAY['Guitar', 'Piano'], 'Musician'),
  ('ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3', (SELECT id FROM auth.users WHERE email = 'user2@example.com'), 'user2@example.com', '+9876543210', NULL, 'ACTIVE', 'Jane', 'Smith', false, NULL, NOW(), 'Bass player', ARRAY['Bass Guitar'], 'Musician');

-- seed data for "users_bands" table
INSERT INTO public.users_bands (user_id, band_id, created_at)
VALUES 
    ('8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', 'b63df5e0-9f5f-420e-a6d7-7c96c03f8724', NOW()),
    ('ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3', 'b63df5e0-9f5f-420e-a6d7-7c96c03f8724', NOW());

-- Seed data for "events" table
INSERT INTO public.events (id, created_at, event_name, description, event_date, start_time, end_time, band_id, creator_user_id, owner_user_id)
VALUES 
  ('db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', NOW(), 'High School Concert', 'Annual concert showcasing our talented students', '2023-04-15', '18:00', '21:00', 'b63df5e0-9f5f-420e-a6d7-7c96c03f8724', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0'),
  ('eb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f6', NOW(), 'Jazz Night', 'An evening filled with smooth jazz melodies', '2023-05-20', '20:00', '23:00', 'b63df5e0-9f5f-420e-a6d7-7c96c03f8724', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0'),
  ('fb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0fa', NOW(), 'Rock Fest', 'A high-energy rock concert featuring local bands', '2023-06-10', '19:00', '22:00', 'b63df5e0-9f5f-420e-a6d7-7c96c03f8724', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3');

-- Seed data for "groups" table
INSERT INTO public.groups (id, created_at, group_name, band_id)
VALUES 
  ('eb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f6', NOW(), 'Jazz Ensemble', 'b56d3c61-8e5b-4c3a-b8b9-1c2f71d3e0f1'),
  ('fb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0fa', NOW(), 'Rock Band', 'b56d3c61-8e5b-4c3a-b8b9-1c2f71d3e0f1');

-- Seed data for "users_groups" table
INSERT INTO public.users_groups (group_id, user_id, created_at)
VALUES
    ('eb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f6','8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', NOW()),
    ('eb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f6', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3', NOW()),
    ('fb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0fa','8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', NOW());

-- Seed data for "conversations" table
INSERT INTO public.conversations (id, created_at, band_id, event_id, group_id, user_id_a, user_id_b, conversation_type)
VALUES 
  ('9b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f2', NOW(), NULL, NULL, NULL, '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3', 'USER'),
  ('cb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f4', NOW(), NULL, 'db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', NULL, NULL, NULL, 'EVENT'),
  ('a2f53438-5e4c-4ce2-8550-c6de806bf7a4', NOW(), NULL, NULL, 'eb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f6', NULL, NULL, 'GROUP');

-- Seed data for "images" table
INSERT INTO public.images (id, created_at, image_name, image_path)
VALUES 
  ('b1e3f628-ca38-473f-9b01-294442b239ff', NOW(), 'ConcertImage1.jpg', '/images/concert_image1.jpg');

-- Seed data for "messages" table
INSERT INTO public.messages (id, created_at, context, conversation_id, user_id)
VALUES 
  ('fb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0fa', NOW(), 'Hey, we can practice for the upcoming concert!', '9b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f2', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0'),
  ('3a4f4a26-8f31-11ee-b9d1-0242ac120002', NOW(), 'Sure, I am available tomorrow afternoon.', '9b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f2', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3'),
  ('e493c30a-5ad6-45c2-b8e5-6d4b29070a10', NOW(), 'Great! We can meet at the practice room.', '9b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f2', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0'),
  ('f7325617-40b0-427f-8148-2aceb8001d9e', NOW(), 'Hello everyone! Do not forget about the Jazz Night rehearsal.', 'cb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f4', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3'),
  ('2dc27a88-9303-4c0d-9ba5-a66bbb08efaa', NOW(), 'See you all there!', 'cb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f4', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3'),
  ('f63f0041-1085-4fd1-9c23-79997596eb66', NOW(), 'Welcome to our group everyone!', 'a2f53438-5e4c-4ce2-8550-c6de806bf7a4', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3'),
  ('0c961735-d6a3-4172-9a01-4f9b0662d908', NOW(), '', 'cb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f4', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3'),
  ('6f26dc40-7036-4b69-8638-719414a9b4b3', NOW(), '', 'cb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f4', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3');

-- Seed data for "events_groups" table
INSERT INTO public.events_groups (created_at, event_id, group_id)
VALUES 
  (NOW(), 'db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', 'eb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f6'),
  (NOW(), 'fb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0fa', 'eb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f6');

-- Seed data for "events_images" table
INSERT INTO public.events_images (created_at, event_id, image_id)
VALUES 
  (NOW(), 'db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', 'b1e3f628-ca38-473f-9b01-294442b239ff');

-- -- Seed data for "event_attendance" table
INSERT INTO public.event_attendance (created_at, status, event_id, user_id)
VALUES 
  (NOW(), 'ATTENDING', 'db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0'),
  (NOW(), 'NOT_ATTENDING', 'db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', 'ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3');

-- Seed data for "files" table
INSERT INTO public.files (id, created_at, file_name, file_path)
VALUES 
  ('8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', NOW(), 'SampleFile1.pdf', '/files/sample1.pdf'),
  ('e9bb84cc-1e3a-4939-9f93-99e16d32a2b1', NOW(), 'SampleFile2.docx', '/files/sample2.docx');

-- Seed data for "events_files" table
INSERT INTO public.events_files (created_at, event_id, file_id)
VALUES 
  (NOW(), 'db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0'),
  (NOW(), 'db6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f5', 'e9bb84cc-1e3a-4939-9f93-99e16d32a2b1');


-- Seed data for "message_attachments" table
INSERT INTO public.message_attachments (created_at, file_id, image_id, message_id)
VALUES 
  (NOW(), '8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', NULL, '0c961735-d6a3-4172-9a01-4f9b0662d908'),
  (NOW(), NULL, 'b1e3f628-ca38-473f-9b01-294442b239ff', '6f26dc40-7036-4b69-8638-719414a9b4b3');

-- Seed data for "message_read_status" table
INSERT INTO public.message_read_status (user_id, message_id, is_read)
VALUES 
  ('8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', 'fb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0fa', true),
  ('ab6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f3', 'fb6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0fa', false),
  ('8b6d3c61-9e5b-4c3a-b8b9-1c2f71d3e0f0', '3a4f4a26-8f31-11ee-b9d1-0242ac120002', true);



