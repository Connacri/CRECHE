-- SQL Migration Script for Crèche App
-- This script aligns Supabase tables with the Flutter models in the repository.

-- 1. Table: users
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY, -- Matches Firebase UID
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    role TEXT DEFAULT 'parent',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    deactivated_at TIMESTAMPTZ,
    scheduled_deletion_date TIMESTAMPTZ,
    profile_images JSONB DEFAULT '{}'::jsonb,
    location JSONB,
    bio TEXT,
    phone_number TEXT,
    metadata JSONB,
    profile_completed BOOLEAN DEFAULT FALSE,
    palmares TEXT,
    diplomas TEXT[],
    certificates TEXT[],
    cv_url TEXT
);

-- 2. Table: children
CREATE TABLE IF NOT EXISTS public.children (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT,
    photo_url TEXT,
    birth_certificate_url TEXT,
    medical_certificate_url TEXT,
    school_grade TEXT,
    medical_info JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Table: courses
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    price NUMERIC,
    season TEXT,
    season_start_date TIMESTAMPTZ,
    season_end_date TIMESTAMPTZ,
    location JSONB,
    images JSONB DEFAULT '[]'::jsonb,
    created_by UUID REFERENCES public.users(id),
    club_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    max_students INTEGER DEFAULT 30,
    current_students INTEGER DEFAULT 0,
    tags TEXT[],
    metadata JSONB,
    min_age INTEGER,
    max_age INTEGER
);

-- 4. Table: enrollments
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending',
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES public.users(id),
    rejection_reason TEXT,
    payment_status TEXT DEFAULT 'pending',
    total_amount NUMERIC,
    paid_amount NUMERIC DEFAULT 0,
    attendance_history JSONB DEFAULT '[]'::jsonb,
    metadata JSONB
);

-- 5. Table: events
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT DEFAULT 'autre',
    status TEXT DEFAULT 'draft',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    registration_deadline TIMESTAMPTZ,
    location JSONB,
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    is_paid BOOLEAN DEFAULT FALSE,
    price NUMERIC,
    member_price NUMERIC,
    is_public BOOLEAN DEFAULT TRUE,
    requires_medical_cert BOOLEAN DEFAULT FALSE,
    images TEXT[],
    target_roles TEXT[],
    allowed_categories TEXT[],
    tags TEXT[],
    metadata JSONB,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Table: event_registrations
CREATE TABLE IF NOT EXISTS public.event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    registrant_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending',
    payment_status TEXT DEFAULT 'not_required',
    paid_amount NUMERIC DEFAULT 0,
    bib_number TEXT,
    category TEXT,
    medical_cert_submitted BOOLEAN DEFAULT FALSE,
    notes TEXT,
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Table: daily_activities
CREATE TABLE IF NOT EXISTS public.daily_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending',
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Table: school_available_slots
CREATE TABLE IF NOT EXISTS public.school_available_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL, -- 0=Monday, etc.
    time_slot JSONB NOT NULL,
    is_occupied BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Table: session_schedules
CREATE TABLE IF NOT EXISTS public.session_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    enrollment_id UUID REFERENCES public.enrollments(id) ON DELETE SET NULL,
    day_of_week INTEGER NOT NULL,
    time_slot JSONB NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancellation_reason TEXT,
    current_enrollment INTEGER DEFAULT 0,
    max_capacity INTEGER DEFAULT 30,
    location TEXT,
    coach_id UUID REFERENCES public.users(id),
    room_name TEXT,
    school_id UUID REFERENCES public.users(id),
    metadata JSONB
);

-- 10. Table: members (Club Members)
CREATE TABLE IF NOT EXISTS public.members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    membership_number TEXT,
    membership_type TEXT DEFAULT 'standard',
    status TEXT DEFAULT 'active',
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB
);

-- 11. Table: coaching_history (Coach Assignments)
CREATE TABLE IF NOT EXISTS public.coaching_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    coach_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'main',
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    unassigned_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB
);

-- 12. Table: invoices
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    member_id UUID REFERENCES public.members(id) ON DELETE CASCADE,
    invoice_number TEXT UNIQUE NOT NULL,
    total_amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending',
    due_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB
);

-- 13. Table: club_expenses
CREATE TABLE IF NOT EXISTS public.club_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    category TEXT,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. Table: payments
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    payment_method TEXT,
    transaction_id TEXT,
    date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. Table: inventory_items
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    quantity INTEGER DEFAULT 0,
    min_quantity INTEGER DEFAULT 0,
    unit TEXT,
    category TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. Table: inventory_transactions
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    club_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL, -- 'in', 'out', 'adjustment'
    quantity INTEGER NOT NULL,
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.children ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_available_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coaching_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

-- Note: Policies depend on the specific access requirements.
-- The app uses 'x-firebase-id' header which is NOT standard for Supabase RLS.
-- Standard RLS usually uses auth.uid().
-- If the app relies on Service Role (adminClient) for most operations, RLS is bypassed.

-- Example Policy for users (using standard auth.uid() if you switch to Supabase Auth):
-- CREATE POLICY "Users can view their own data" ON public.users FOR SELECT USING (auth.uid() = id);

-- If you keep the 'x-firebase-id' custom header approach, you can use:
-- CREATE OR REPLACE FUNCTION get_firebase_id() RETURNS text AS $$
--     SELECT current_setting('request.headers', true)::json->>'x-firebase-id';
-- $$ LANGUAGE SQL STABLE;

-- Then use it in policies:
-- CREATE POLICY "Allow based on x-firebase-id" ON public.users FOR ALL USING (id::text = get_firebase_id());

-- 17. RPC Functions

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
    -- Revenue from enrollments
    SELECT COALESCE(SUM(paid_amount), 0) INTO total_revenue
    FROM public.enrollments e
    JOIN public.courses c ON e.course_id = c.id
    WHERE c.created_by = p_club_id
    AND EXTRACT(YEAR FROM e.enrolled_at) = p_year;

    -- Expenses
    SELECT COALESCE(SUM(amount), 0) INTO total_expenses
    FROM public.club_expenses
    WHERE club_id = p_club_id
    AND EXTRACT(YEAR FROM date) = p_year;

    -- Enrollments count
    SELECT COUNT(*) INTO total_enrollments
    FROM public.enrollments e
    JOIN public.courses c ON e.course_id = c.id
    WHERE c.created_by = p_club_id
    AND EXTRACT(YEAR FROM e.enrolled_at) = p_year;

    -- Active courses
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

-- RPC: get_club_subscription_status (Placeholder)
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
