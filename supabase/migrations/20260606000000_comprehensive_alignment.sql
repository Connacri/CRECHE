-- =====================================================================
-- RECONSTRUCTION ET ALIGNEMENT TOTAL DU SCHÉMA (CLUB/CRECHE)
-- =====================================================================

-- 1. Nettoyage de l'environnement et fonction d'authentification
DROP FUNCTION IF EXISTS public.get_firebase_uid() CASCADE;
CREATE OR REPLACE FUNCTION public.get_firebase_uid() RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('request.headers', true)::json->>'x-firebase-id', '')::uuid;
$$;

-- 2. Drop des tables existantes pour normalisation UUID
DROP TABLE IF EXISTS public.inventory_transactions CASCADE;
DROP TABLE IF EXISTS public.inventory_items CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.invoices CASCADE;
DROP TABLE IF EXISTS public.club_expenses CASCADE;
DROP TABLE IF EXISTS public.attendance_records CASCADE;
DROP TABLE IF EXISTS public.qr_attendance_tokens CASCADE;
DROP TABLE IF EXISTS public.transport_sessions CASCADE;
DROP TABLE IF EXISTS public.geofence_zones CASCADE;
DROP TABLE IF EXISTS public.event_registrations CASCADE;
DROP TABLE IF EXISTS public.events CASCADE;
DROP TABLE IF EXISTS public.coaching_history CASCADE;
DROP TABLE IF EXISTS public.members CASCADE;
DROP TABLE IF EXISTS public.membership_plans CASCADE;
DROP TABLE IF EXISTS public.daily_menus CASCADE;
DROP TABLE IF EXISTS public.menu_items CASCADE;
DROP TABLE IF EXISTS public.creche_stories CASCADE;

-- 3. Recréation des tables alignées sur les modèles Flutter

-- MEMBERSHIPS
CREATE TABLE public.membership_plans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    membership_type text NOT NULL,
    duration_months integer NOT NULL DEFAULT 12,
    price decimal(10,2) NOT NULL,
    features jsonb DEFAULT '[]',
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    current_plan_id uuid REFERENCES public.membership_plans(id),
    membership_number text UNIQUE,
    status text DEFAULT 'pending',
    start_date date DEFAULT CURRENT_DATE,
    end_date date,
    auto_renew boolean DEFAULT false,
    medical_info jsonb DEFAULT '{}',
    emergency_contact jsonb DEFAULT '{}',
    notes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- EVENTS
CREATE TABLE public.events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    type text NOT NULL,
    status text DEFAULT 'draft',
    start_date timestamptz NOT NULL,
    end_date timestamptz NOT NULL,
    registration_deadline timestamptz,
    location jsonb DEFAULT '{}',
    max_participants integer,
    current_participants integer DEFAULT 0,
    is_paid boolean DEFAULT false,
    price decimal(10,2),
    member_price decimal(10,2),
    is_public boolean DEFAULT true,
    requires_medical_cert boolean DEFAULT false,
    images jsonb DEFAULT '[]',
    target_roles text[] DEFAULT '{}',
    allowed_categories text[] DEFAULT '{}',
    tags text[] DEFAULT '{}',
    metadata jsonb DEFAULT '{}',
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.event_registrations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    registrant_id uuid NOT NULL REFERENCES public.users(id),
    child_id uuid REFERENCES public.children(id),
    status text DEFAULT 'pending',
    payment_status text DEFAULT 'not_required',
    paid_amount decimal(10,2) DEFAULT 0,
    bib_number text,
    category text,
    medical_cert_submitted boolean DEFAULT false,
    notes text,
    registered_at timestamptz DEFAULT now(),
    confirmed_at timestamptz,
    updated_at timestamptz DEFAULT now()
);

-- FINANCES (Expertise Comptable)
CREATE TABLE public.invoices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    invoice_number text UNIQUE,
    type text NOT NULL,
    status text DEFAULT 'pending',
    parent_id uuid REFERENCES public.users(id),
    child_id uuid REFERENCES public.children(id),
    enrollment_id uuid REFERENCES public.enrollments(id),
    event_registration_id uuid REFERENCES public.event_registrations(id),
    items jsonb DEFAULT '[]',
    subtotal decimal(10,2) DEFAULT 0,
    vat_rate decimal(5,2) DEFAULT 0,
    vat_amount decimal(10,2) DEFAULT 0,
    discount_percent decimal(5,2) DEFAULT 0,
    discount_amount decimal(10,2) DEFAULT 0,
    total_amount decimal(10,2) NOT NULL DEFAULT 0,
    paid_amount decimal(10,2) DEFAULT 0,
    issue_date date DEFAULT CURRENT_DATE,
    due_date date,
    recipient_name text,
    recipient_email text,
    notes text,
    metadata jsonb DEFAULT '{}',
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    invoice_id uuid REFERENCES public.invoices(id) ON DELETE SET NULL,
    member_id uuid REFERENCES public.users(id),
    amount decimal(10,2) NOT NULL,
    currency text DEFAULT 'DZD',
    payment_method text NOT NULL,
    status text DEFAULT 'completed',
    transaction_id text,
    receipt_url text,
    payment_date date DEFAULT CURRENT_DATE,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.club_expenses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    title text NOT NULL,
    description text,
    category text NOT NULL,
    amount decimal(10,2) NOT NULL,
    date date DEFAULT CURRENT_DATE,
    payment_method text,
    receipt_url text,
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now()
);

-- INVENTORY
CREATE TABLE public.inventory_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    name text NOT NULL,
    description text,
    category text,
    sku text,
    barcode text,
    unit_price decimal(10,2) DEFAULT 0,
    sale_price decimal(10,2) DEFAULT 0,
    quantity_in_stock integer DEFAULT 0,
    min_quantity_alert integer DEFAULT 5,
    images jsonb DEFAULT '[]',
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.inventory_transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id uuid REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    club_id uuid NOT NULL REFERENCES public.users(id),
    transaction_type text NOT NULL,
    quantity integer NOT NULL,
    unit_price decimal(10,2),
    total_price decimal(10,2),
    related_invoice_id uuid REFERENCES public.invoices(id),
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now()
);

-- TRANSPORT & GEOFENCING
CREATE TABLE public.transport_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    driver_id uuid REFERENCES public.users(id),
    vehicle_id text,
    route_name text,
    status text DEFAULT 'scheduled',
    start_time timestamptz,
    end_time timestamptz,
    actual_start_time timestamptz,
    actual_end_time timestamptz,
    current_lat decimal(10,8),
    current_lng decimal(11,8),
    distance_km decimal(10,2),
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.geofence_zones (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    name text NOT NULL,
    description text,
    latitude decimal(10,8) NOT NULL,
    longitude decimal(11,8) NOT NULL,
    radius_meters decimal(10,2) DEFAULT 100,
    zone_type text DEFAULT 'circle',
    polygon_coords jsonb,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- CRECHE SPECIFIC (Menus & Stories)
CREATE TABLE public.daily_menus (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    date date NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(club_id, date)
);

CREATE TABLE public.menu_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_id uuid NOT NULL REFERENCES public.daily_menus(id) ON DELETE CASCADE,
    category text NOT NULL,
    title text NOT NULL,
    description text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.creche_stories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    content text,
    cover_image text,
    author_id uuid REFERENCES public.users(id),
    is_public boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ATTENDANCE
CREATE TABLE public.attendance_records (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    session_id uuid REFERENCES public.session_schedules(id),
    enrollment_id uuid REFERENCES public.enrollments(id),
    child_id uuid REFERENCES public.children(id),
    date date NOT NULL,
    check_in_time timestamptz,
    check_out_time timestamptz,
    method text DEFAULT 'manual',
    is_present boolean DEFAULT true,
    is_late boolean DEFAULT false,
    check_in_lat decimal(10,8),
    check_in_lng decimal(11,8),
    recorded_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.qr_attendance_tokens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    session_id uuid REFERENCES public.session_schedules(id),
    token text NOT NULL UNIQUE DEFAULT gen_random_uuid()::text,
    date date NOT NULL DEFAULT current_date,
    expires_at timestamptz NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- 4. RLS - Activation et Politiques

DO $$
DECLARE
    t text;
BEGIN
    FOR t IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- Final security policies logic is maintained in database.
