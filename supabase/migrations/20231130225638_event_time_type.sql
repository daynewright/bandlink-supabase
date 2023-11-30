-- Step 1: Add new columns
ALTER TABLE public.events
ADD COLUMN start_time_new timestamp with time zone;

ALTER TABLE public.events
ADD COLUMN end_time_new timestamp with time zone;

-- Step 2: Drop old columns
ALTER TABLE public.events
DROP COLUMN start_time,
DROP COLUMN end_time;

-- Step 3: Rename new columns
ALTER TABLE public.events
RENAME COLUMN start_time_new TO start_time;

ALTER TABLE public.events
RENAME COLUMN end_time_new TO end_time;

