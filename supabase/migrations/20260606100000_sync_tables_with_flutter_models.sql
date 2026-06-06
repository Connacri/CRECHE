-- 🚀 MIGRATION DE SYNCHRONISATION : Tables Supabase <-> Modèles Flutter
-- Auteur: Jules
-- Date: 2026-06-06

-- 1. Table COURSES : Ajout des tranches d'âge
ALTER TABLE public.courses
ADD COLUMN IF NOT EXISTS min_age integer,
ADD COLUMN IF NOT EXISTS max_age integer;

COMMENT ON COLUMN public.courses.min_age IS 'Âge minimum pour participer au cours';
COMMENT ON COLUMN public.courses.max_age IS 'Âge maximum pour participer au cours';

-- 2. Table SESSION_SCHEDULES : Liaison coach et détails salle
ALTER TABLE public.session_schedules
ADD COLUMN IF NOT EXISTS coach_id text,
ADD COLUMN IF NOT EXISTS room_name text;

COMMENT ON COLUMN public.session_schedules.coach_id IS 'ID du coach assigné à cette session spécifique';
COMMENT ON COLUMN public.session_schedules.room_name IS 'Nom ou numéro de la salle où se déroule la session';

-- 3. Table USERS : Champs professionnels et statut profil
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS profile_completed boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS palmares text;

COMMENT ON COLUMN public.users.profile_completed IS 'Indique si l''utilisateur a rempli toutes les informations de son profil';
COMMENT ON COLUMN public.users.palmares IS 'Texte décrivant l''expérience et les accomplissements professionnels (Coach/School)';

-- 4. Table DAILY_ACTIVITIES : Horodatage de mise à jour
ALTER TABLE public.daily_activities
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 5. Table EVENT_REGISTRATIONS : Horodatage de mise à jour
ALTER TABLE public.event_registrations
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 6. Trigger automatique pour updated_at (si la fonction existe déjà dans votre schéma)
-- On s'assure que la fonction de mise à jour existe
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Application des triggers
DROP TRIGGER IF EXISTS set_updated_at ON public.daily_activities;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.daily_activities
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at ON public.event_registrations;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.event_registrations
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
