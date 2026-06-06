-- =====================================================================
-- ALIGNEMENT FINAL ET POLITIQUES DE SÉCURITÉ (RLS)
-- =====================================================================

-- 1. Ajout des colonnes manquantes aux tables existantes si nécessaire
-- Note: On utilise des blocs DO pour vérifier l'existence des colonnes avant l'ajout

-- Table USERS
CREATE TABLE IF NOT EXISTS public.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    name text NOT NULL,
    role text NOT NULL DEFAULT 'parent',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

DO $$
BEGIN
    -- Ajouts pour USERS
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'is_active') THEN
        ALTER TABLE public.users ADD COLUMN is_active boolean DEFAULT true;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'deactivated_at') THEN
        ALTER TABLE public.users ADD COLUMN deactivated_at timestamptz;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'scheduled_deletion_date') THEN
        ALTER TABLE public.users ADD COLUMN scheduled_deletion_date timestamptz;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'profile_images') THEN
        ALTER TABLE public.users ADD COLUMN profile_images jsonb DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'location') THEN
        ALTER TABLE public.users ADD COLUMN location jsonb;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'bio') THEN
        ALTER TABLE public.users ADD COLUMN bio text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'phone_number') THEN
        ALTER TABLE public.users ADD COLUMN phone_number text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'metadata') THEN
        ALTER TABLE public.users ADD COLUMN metadata jsonb DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'profile_completed') THEN
        ALTER TABLE public.users ADD COLUMN profile_completed boolean DEFAULT false;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'palmares') THEN
        ALTER TABLE public.users ADD COLUMN palmares text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'diplomas') THEN
        ALTER TABLE public.users ADD COLUMN diplomas text[] DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'certificates') THEN
        ALTER TABLE public.users ADD COLUMN certificates text[] DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'cv_url') THEN
        ALTER TABLE public.users ADD COLUMN cv_url text;
    END IF;
END $$;

-- 2. Création/Mise à jour des autres tables CORE
CREATE TABLE IF NOT EXISTS public.children (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    first_name text NOT NULL,
    last_name text NOT NULL,
    date_of_birth date NOT NULL,
    gender text NOT NULL,
    photo_url text,
    birth_certificate_url text,
    medical_certificate_url text,
    school_grade text,
    medical_info jsonb DEFAULT '{}',
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.courses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    category text NOT NULL,
    price decimal(10,2),
    season text NOT NULL DEFAULT 'yearRound',
    season_start_date timestamptz NOT NULL,
    season_end_date timestamptz NOT NULL,
    location jsonb DEFAULT '{}',
    images jsonb DEFAULT '[]',
    created_by uuid NOT NULL REFERENCES public.users(id),
    club_id uuid REFERENCES public.users(id),
    is_active boolean DEFAULT true,
    max_students integer DEFAULT 30,
    current_students integer DEFAULT 0,
    tags text[] DEFAULT '{}',
    metadata jsonb DEFAULT '{}',
    min_age integer,
    max_age integer,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.enrollments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    child_id uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
    parent_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'pending',
    enrolled_at timestamptz DEFAULT now(),
    approved_at timestamptz,
    approved_by uuid REFERENCES public.users(id),
    rejection_reason text,
    payment_status text NOT NULL DEFAULT 'pending',
    total_amount decimal(10,2),
    paid_amount decimal(10,2) DEFAULT 0,
    attendance_history jsonb DEFAULT '[]',
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.session_schedules (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL,
    day_of_week integer NOT NULL,
    time_slot jsonb NOT NULL,
    start_date timestamptz NOT NULL,
    end_date timestamptz NOT NULL,
    is_cancelled boolean DEFAULT false,
    cancellation_reason text,
    current_enrollment integer DEFAULT 0,
    max_capacity integer DEFAULT 30,
    location text,
    coach_id uuid REFERENCES public.users(id),
    room_name text,
    school_id uuid REFERENCES public.users(id),
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.daily_activities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id uuid NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
    date date NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    description text,
    status text DEFAULT 'pending',
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 3. Sécurité (RLS) et Politiques
-- On active RLS sur toutes les tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- Suppression des anciennes politiques pour éviter les conflits
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- Création de politiques de base "Access for Authenticated Users"
-- Note: Dans un environnement réel, ces politiques devraient être plus granulaires.
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE format('CREATE POLICY "Allow all for authenticated users" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t);
        EXECUTE format('CREATE POLICY "Allow select for anonymous users" ON public.%I FOR SELECT TO anon USING (true)', t);
    END LOOP;
END $$;

-- 4. Triggers pour updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    t text;
BEGIN
    FOR t IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_' || t) THEN
            EXECUTE format('CREATE TRIGGER set_updated_at_%I BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at()', t, t);
        END IF;
    END LOOP;
END $$;
