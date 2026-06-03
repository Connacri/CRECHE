-- Migration: Add school association and available slots

-- 1. Add school_id to session_schedules
ALTER TABLE public.session_schedules
ADD COLUMN school_id text;

CREATE INDEX IF NOT EXISTS session_schedules_school_id_idx ON public.session_schedules (school_id);

-- 2. Create school_available_slots table
CREATE TABLE IF NOT EXISTS public.school_available_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id text NOT NULL,
  day_of_week integer NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  time_slot jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_occupied boolean NOT NULL DEFAULT false,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Add RLS to school_available_slots
ALTER TABLE public.school_available_slots ENABLE ROW LEVEL SECURITY;

-- Schools can manage their own slots
CREATE POLICY "Schools can manage own slots"
ON public.school_available_slots FOR ALL
TO authenticated
USING (school_id = (select auth.uid())::text)
WITH CHECK (school_id = (select auth.uid())::text);

-- Coaches can view school slots
CREATE POLICY "Anyone authenticated can view school slots"
ON public.school_available_slots FOR SELECT
TO authenticated
USING (true);

-- 4. Helper function to get schools
CREATE OR REPLACE FUNCTION public.get_schools()
RETURNS SETOF public.users
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT * FROM public.users WHERE role = 'school' AND is_active = true;
$$;
