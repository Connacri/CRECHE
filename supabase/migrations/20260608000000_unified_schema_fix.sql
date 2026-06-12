-- =====================================================================
-- UNIFIED SCHEMA FIX AND ALIGNMENT (2026-06-08)
-- =====================================================================

-- 1. Ensure Table public.users
CREATE TABLE IF NOT EXISTS public.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    name text NOT NULL,
    role text NOT NULL DEFAULT 'parent',
    is_active boolean DEFAULT true,
    deactivated_at timestamptz,
    scheduled_deletion_date timestamptz,
    profile_images jsonb DEFAULT '{}',
    location jsonb,
    bio text,
    phone_number text,
    metadata jsonb DEFAULT '{}',
    profile_completed boolean DEFAULT false,
    palmares text,
    diplomas text[] DEFAULT '{}',
    certificates text[] DEFAULT '{}',
    cv_url text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2. Ensure Table public.children
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

-- 3. Ensure Table public.courses
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

-- 4. Ensure Table public.enrollments
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

-- 5. Ensure Table public.session_schedules
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

-- 6. Ensure Table public.daily_activities
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

-- 7. Ensure Club Management Tables
CREATE TABLE IF NOT EXISTS public.membership_plans (
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

CREATE TABLE IF NOT EXISTS public.members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    current_plan_id uuid REFERENCES public.membership_plans(id),
    membership_number text,
    status text DEFAULT 'active',
    start_date date DEFAULT CURRENT_DATE,
    end_date date,
    auto_renew boolean DEFAULT false,
    medical_info jsonb DEFAULT '{}',
    emergency_contact jsonb DEFAULT '{}',
    notes text,
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.coaching_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    coach_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role text DEFAULT 'main',
    assigned_at timestamptz DEFAULT now(),
    unassigned_at timestamptz,
    is_active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'
);

-- 8. Ensure Finance Tables
CREATE TABLE IF NOT EXISTS public.invoices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    invoice_number text UNIQUE,
    type text,
    status text DEFAULT 'pending',
    parent_id uuid REFERENCES public.users(id),
    child_id uuid REFERENCES public.children(id),
    enrollment_id uuid REFERENCES public.enrollments(id),
    items jsonb DEFAULT '[]',
    subtotal decimal(10,2) DEFAULT 0,
    vat_rate decimal(5,2) DEFAULT 0,
    vat_amount decimal(10,2) DEFAULT 0,
    total_amount decimal(10,2) NOT NULL DEFAULT 0,
    paid_amount decimal(10,2) DEFAULT 0,
    issue_date date DEFAULT CURRENT_DATE,
    due_date date,
    notes text,
    metadata jsonb DEFAULT '{}',
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    invoice_id uuid REFERENCES public.invoices(id) ON DELETE SET NULL,
    member_id uuid REFERENCES public.users(id),
    amount decimal(10,2) NOT NULL,
    currency text DEFAULT 'DZD',
    payment_method text NOT NULL,
    status text DEFAULT 'completed',
    transaction_id text,
    payment_date date DEFAULT CURRENT_DATE,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.club_expenses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    title text NOT NULL,
    description text,
    category text NOT NULL,
    amount decimal(10,2) NOT NULL,
    date date DEFAULT CURRENT_DATE,
    payment_method text,
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now()
);

-- 9. Ensure Inventory Tables
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id uuid NOT NULL REFERENCES public.users(id),
    name text NOT NULL,
    description text,
    category text,
    unit_price decimal(10,2) DEFAULT 0,
    quantity integer DEFAULT 0,
    min_quantity integer DEFAULT 5,
    images jsonb DEFAULT '[]',
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id uuid REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    club_id uuid NOT NULL REFERENCES public.users(id),
    transaction_type text NOT NULL,
    quantity integer NOT NULL,
    notes text,
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now()
);

-- 10. Ensure Shipments Table
CREATE TABLE IF NOT EXISTS public.shipments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_number text UNIQUE NOT NULL,
    sender_id uuid REFERENCES public.users(id),
    receiver_id uuid REFERENCES public.users(id),
    transporteur_id uuid REFERENCES public.users(id),
    status text DEFAULT 'pending', -- 'pending', 'picked_up', 'in_transit', 'delivered', 'cancelled'
    origin_address text,
    destination_address text,
    current_location jsonb,
    weight decimal(10,2),
    estimated_delivery timestamptz,
    actual_delivery timestamptz,
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 11. RPC Functions

-- RPC: get_schools
CREATE OR REPLACE FUNCTION public.get_schools()
RETURNS SETOF public.users AS $$
BEGIN
    RETURN QUERY SELECT * FROM public.users 
    WHERE role IN ('school', 'club', 'organisation') 
    AND is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: get_owner_enrollments_with_details
CREATE OR REPLACE FUNCTION public.get_owner_enrollments_with_details(owner_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(row_to_json(e_data)) INTO result
    FROM (
        SELECT 
            e.*,
            row_to_json(c) as courses,
            row_to_json(ch) as children
        FROM public.enrollments e
        JOIN public.courses c ON e.course_id = c.id
        JOIN public.children ch ON e.child_id = ch.id
        WHERE c.created_by = owner_id
    ) e_data;
    
    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: get_club_financial_summary
CREATE OR REPLACE FUNCTION public.get_club_financial_summary(p_club_id UUID, p_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE))
RETURNS JSONB AS $$
DECLARE
    total_revenue NUMERIC;
    total_expenses NUMERIC;
    total_enrollments INTEGER;
    active_courses INTEGER;
BEGIN
    SELECT COALESCE(SUM(paid_amount), 0) INTO total_revenue
    FROM public.enrollments e
    JOIN public.courses c ON e.course_id = c.id
    WHERE c.created_by = p_club_id AND EXTRACT(YEAR FROM e.enrolled_at) = p_year;

    SELECT COALESCE(SUM(amount), 0) INTO total_expenses
    FROM public.club_expenses
    WHERE club_id = p_club_id AND EXTRACT(YEAR FROM date) = p_year;

    SELECT COUNT(*) INTO total_enrollments
    FROM public.enrollments e
    JOIN public.courses c ON e.course_id = c.id
    WHERE c.created_by = p_club_id AND EXTRACT(YEAR FROM e.enrolled_at) = p_year;

    SELECT COUNT(*) INTO active_courses
    FROM public.courses
    WHERE created_by = p_club_id AND is_active = TRUE;

    RETURN jsonb_build_object(
        'total_revenue', total_revenue,
        'total_expenses', total_expenses,
        'total_enrollments', total_enrollments,
        'active_courses', active_courses,
        'net_income', total_revenue - total_expenses
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: get_club_subscription_status
CREATE OR REPLACE FUNCTION public.get_club_subscription_status(p_club_id UUID)
RETURNS JSONB AS $$
BEGIN
    RETURN jsonb_build_object(
        'status', 'active',
        'plan', 'premium',
        'expires_at', (CURRENT_DATE + INTERVAL '1 year')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Row Level Security (RLS)
-- Standard activation for all tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.%I', t);
        EXECUTE format('CREATE POLICY "Allow all for authenticated users" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t);
    END LOOP;
END $$;
