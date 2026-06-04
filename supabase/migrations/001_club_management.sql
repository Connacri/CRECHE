-- =====================================================================
-- MIGRATION 001: Club Management Platform — creche app extension
-- Run in Supabase SQL Editor
-- =====================================================================

-- ── 1. EVENTS ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    title TEXT NOT NULL CHECK (char_length(title) >= 3 AND char_length(title) <= 200),
    description TEXT,
    type TEXT NOT NULL CHECK (type IN (
        'competition','stage','porte_ouverte','reunion','examen','tournoi','gala','autre'
    )),
    status TEXT DEFAULT 'draft' CHECK (status IN (
        'draft','published','registration_open','ongoing','completed','cancelled'
    )),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    registration_deadline TIMESTAMPTZ,
    location JSONB DEFAULT '{}',
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    is_paid BOOLEAN DEFAULT false,
    price DECIMAL(10,2),
    member_price DECIMAL(10,2),          -- prix réduit adhérents
    is_public BOOLEAN DEFAULT true,
    requires_medical_cert BOOLEAN DEFAULT false,
    images JSONB DEFAULT '[]',
    target_roles TEXT[] DEFAULT '{}',    -- qui peut s'inscrire
    allowed_categories TEXT[] DEFAULT '{}', -- catégories sport (U10, U12, senior…)
    tags TEXT[] DEFAULT '{}',
    metadata JSONB,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (end_date > start_date)
);

-- ── 2. EVENT REGISTRATIONS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    registrant_id TEXT NOT NULL,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'pending','confirmed','waitlisted','cancelled','attended','no_show'
    )),
    payment_status TEXT DEFAULT 'not_required' CHECK (payment_status IN (
        'not_required','pending','paid','refunded'
    )),
    paid_amount DECIMAL(10,2) DEFAULT 0,
    bib_number TEXT,
    category TEXT,
    medical_cert_submitted BOOLEAN DEFAULT false,
    notes TEXT,
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. MEMBERS (adhérents adultes) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    club_id TEXT NOT NULL,
    membership_number TEXT UNIQUE,
    membership_type TEXT DEFAULT 'standard' CHECK (membership_type IN (
        'standard','premium','family','trial','honorary','reduced'
    )),
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'active','expired','suspended','pending','cancelled'
    )),
    start_date DATE,
    end_date DATE,
    sport_level TEXT CHECK (sport_level IN (
        'debutant','intermediaire','avance','expert','competition'
    )),
    license_number TEXT,
    license_federation TEXT,
    sport_categories TEXT[] DEFAULT '{}',   -- U10, U12, senior, veteran…
    medical_info JSONB DEFAULT '{}',
    emergency_contact JSONB DEFAULT '{}',
    photo_url TEXT,
    notes TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, club_id)
);

-- ── 4. MEMBERSHIP PLANS (tarifs du club) ───────────────────────────
CREATE TABLE IF NOT EXISTS membership_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    membership_type TEXT NOT NULL,
    duration_months INTEGER NOT NULL CHECK (duration_months IN (1,3,6,12)),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    features JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. INVOICES ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    invoice_number TEXT UNIQUE,
    type TEXT NOT NULL CHECK (type IN (
        'subscription','session','event','seasonal','license','equipment','custom'
    )),
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'draft','sent','pending','partial','paid','overdue','cancelled'
    )),
    -- Références flexibles
    member_id UUID REFERENCES members(id),
    parent_id TEXT,
    child_id UUID REFERENCES children(id),
    enrollment_id UUID REFERENCES enrollments(id),
    event_registration_id UUID REFERENCES event_registrations(id),
    -- Montants
    items JSONB NOT NULL DEFAULT '[]',
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    -- Dates
    issue_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    -- Meta
    recipient_name TEXT,
    recipient_email TEXT,
    notes TEXT,
    payment_instructions TEXT,
    metadata JSONB,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. PAYMENTS ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    method TEXT NOT NULL CHECK (method IN (
        'cash','bank_transfer','ccp','edahabia','baridimob','cheque','online','other'
    )),
    reference TEXT,
    status TEXT DEFAULT 'completed' CHECK (status IN (
        'pending','completed','failed','refunded'
    )),
    paid_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    receipt_url TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. CLUB EXPENSES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS club_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'equipment','venue','staff','transport','marketing',
        'utilities','license_fees','maintenance','medical','other'
    )),
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    date DATE NOT NULL,
    supplier TEXT,
    receipt_url TEXT,
    payment_method TEXT,
    is_recurring BOOLEAN DEFAULT false,
    recurrence TEXT,
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 8. ATTENDANCE RECORDS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    session_id UUID REFERENCES session_schedules(id),
    enrollment_id UUID REFERENCES enrollments(id),
    child_id UUID REFERENCES children(id),
    member_id UUID REFERENCES members(id),
    date DATE NOT NULL,
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    method TEXT DEFAULT 'manual' CHECK (method IN (
        'manual','qr_code','gps','nfc'
    )),
    is_present BOOLEAN DEFAULT true,
    is_late BOOLEAN DEFAULT false,
    check_in_lat DECIMAL(10,8),
    check_in_lng DECIMAL(11,8),
    qr_token TEXT,
    notes TEXT,
    recorded_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 9. GEOFENCE ZONES ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS geofence_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    center_lat DECIMAL(10,8) NOT NULL,
    center_lng DECIMAL(11,8) NOT NULL,
    radius_meters DECIMAL(8,2) DEFAULT 100,
    type TEXT DEFAULT 'venue' CHECK (type IN (
        'venue','transport_stop','restricted','safe_zone'
    )),
    is_active BOOLEAN DEFAULT true,
    alert_on_entry BOOLEAN DEFAULT false,
    alert_on_exit BOOLEAN DEFAULT true,
    color TEXT DEFAULT '#4CAF50',
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 10. TRANSPORT SESSIONS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transport_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    driver_id TEXT,
    driver_name TEXT,
    vehicle_name TEXT,
    vehicle_plate TEXT,
    route_name TEXT,
    stops JSONB DEFAULT '[]',
    passenger_child_ids JSONB DEFAULT '[]',
    status TEXT DEFAULT 'idle' CHECK (status IN (
        'idle','en_route','at_stop','completed','cancelled'
    )),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    session_date DATE DEFAULT CURRENT_DATE,
    current_lat DECIMAL(10,8),
    current_lng DECIMAL(11,8),
    track_points JSONB DEFAULT '[]',
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 11. QR TOKENS (présence QR code) ──────────────────────────────
CREATE TABLE IF NOT EXISTS qr_attendance_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    session_id UUID REFERENCES session_schedules(id),
    token TEXT NOT NULL UNIQUE DEFAULT gen_random_uuid()::TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    expires_at TIMESTAMPTZ NOT NULL,
    scans_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_events_club_id ON events(club_id);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);

CREATE INDEX IF NOT EXISTS idx_event_reg_event_id ON event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reg_registrant ON event_registrations(registrant_id);
CREATE INDEX IF NOT EXISTS idx_event_reg_child ON event_registrations(child_id);

CREATE INDEX IF NOT EXISTS idx_members_club_id ON members(club_id);
CREATE INDEX IF NOT EXISTS idx_members_user_id ON members(user_id);
CREATE INDEX IF NOT EXISTS idx_members_status ON members(status);

CREATE INDEX IF NOT EXISTS idx_invoices_club_id ON invoices(club_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_member_id ON invoices(member_id);

CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON payments(invoice_id);

CREATE INDEX IF NOT EXISTS idx_expenses_club_id ON club_expenses(club_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON club_expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON club_expenses(category);

CREATE INDEX IF NOT EXISTS idx_attendance_session_id ON attendance_records(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_attendance_club_id ON attendance_records(club_id);

-- ═══════════════════════════════════════════════════════════════════
-- FUNCTIONS & TRIGGERS
-- ═══════════════════════════════════════════════════════════════════

-- Auto-generate invoice number: INV-202506-0001
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
    prefix TEXT := 'INV-' || TO_CHAR(NOW(), 'YYYYMM') || '-';
    seq INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO seq
    FROM invoices
    WHERE created_at >= DATE_TRUNC('month', NOW());
    RETURN prefix || LPAD(seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_set_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number := generate_invoice_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_number ON invoices;
CREATE TRIGGER trg_invoice_number
BEFORE INSERT ON invoices
FOR EACH ROW EXECUTE FUNCTION trigger_set_invoice_number();

-- Auto-generate membership number: MBR-25-00001
CREATE OR REPLACE FUNCTION generate_membership_number()
RETURNS TEXT AS $$
DECLARE
    prefix TEXT := 'MBR-' || TO_CHAR(NOW(), 'YY') || '-';
    seq INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO seq FROM members WHERE EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW());
    RETURN prefix || LPAD(seq::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_set_membership_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.membership_number IS NULL OR NEW.membership_number = '' THEN
        NEW.membership_number := generate_membership_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_membership_number ON members;
CREATE TRIGGER trg_membership_number
BEFORE INSERT ON members
FOR EACH ROW EXECUTE FUNCTION trigger_set_membership_number();

-- Update invoice paid_amount + status when payment recorded
CREATE OR REPLACE FUNCTION trigger_update_invoice_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_paid DECIMAL;
    v_total DECIMAL;
BEGIN
    SELECT COALESCE(SUM(amount),0) INTO v_paid
    FROM payments WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id) AND status = 'completed';

    SELECT total_amount INTO v_total FROM invoices WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);

    UPDATE invoices SET
        paid_amount = v_paid,
        status = CASE
            WHEN v_paid >= v_total THEN 'paid'
            WHEN v_paid > 0 THEN 'partial'
            ELSE 'pending'
        END,
        updated_at = NOW()
    WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_on_payment ON payments;
CREATE TRIGGER trg_invoice_on_payment
AFTER INSERT OR UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION trigger_update_invoice_on_payment();

-- Auto-update event participant count
CREATE OR REPLACE FUNCTION trigger_event_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE events SET
        current_participants = (
            SELECT COUNT(*) FROM event_registrations
            WHERE event_id = COALESCE(NEW.event_id, OLD.event_id)
              AND status IN ('confirmed','attended')
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.event_id, OLD.event_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_event_participants ON event_registrations;
CREATE TRIGGER trg_event_participants
AFTER INSERT OR UPDATE OR DELETE ON event_registrations
FOR EACH ROW EXECUTE FUNCTION trigger_event_participant_count();

-- ═══════════════════════════════════════════════════════════════════
-- RPC FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

-- Finance summary for a club/year
CREATE OR REPLACE FUNCTION get_club_financial_summary(
    p_club_id TEXT,
    p_year INTEGER DEFAULT EXTRACT(YEAR FROM NOW())::INTEGER
)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE result JSONB;
BEGIN
    WITH rev AS (
        SELECT
            COALESCE(SUM(paid_amount), 0)                                                     AS total_revenue,
            COALESCE(SUM(total_amount - paid_amount) FILTER (WHERE status = 'overdue'), 0)    AS overdue_amount,
            COALESCE(SUM(total_amount - paid_amount) FILTER (
                WHERE status IN ('pending','partial','sent')), 0)                              AS pending_amount
        FROM invoices
        WHERE club_id = p_club_id AND EXTRACT(YEAR FROM created_at) = p_year
    ),
    exp AS (
        SELECT COALESCE(SUM(amount), 0) AS total_expenses
        FROM club_expenses
        WHERE club_id = p_club_id AND EXTRACT(YEAR FROM date) = p_year
    ),
    monthly AS (
        SELECT
            m,
            COALESCE((SELECT SUM(paid_amount) FROM invoices
                WHERE club_id = p_club_id AND EXTRACT(YEAR FROM created_at) = p_year
                AND EXTRACT(MONTH FROM created_at) = m), 0) AS revenue,
            COALESCE((SELECT SUM(amount) FROM club_expenses
                WHERE club_id = p_club_id AND EXTRACT(YEAR FROM date) = p_year
                AND EXTRACT(MONTH FROM date) = m), 0) AS expenses
        FROM generate_series(1,12) m
    ),
    by_type AS (
        SELECT type, COALESCE(SUM(paid_amount),0) AS amount
        FROM invoices
        WHERE club_id = p_club_id AND EXTRACT(YEAR FROM created_at) = p_year
        GROUP BY type
    ),
    by_exp_cat AS (
        SELECT category, COALESCE(SUM(amount),0) AS amount
        FROM club_expenses
        WHERE club_id = p_club_id AND EXTRACT(YEAR FROM date) = p_year
        GROUP BY category
    )
    SELECT jsonb_build_object(
        'total_revenue',    r.total_revenue,
        'total_expenses',   e.total_expenses,
        'net_profit',       r.total_revenue - e.total_expenses,
        'pending_amount',   r.pending_amount,
        'overdue_amount',   r.overdue_amount,
        'monthly',          (SELECT jsonb_agg(jsonb_build_object(
                                'month', m, 'revenue', revenue, 'expenses', expenses
                            ) ORDER BY m) FROM monthly),
        'revenue_by_type',  (SELECT jsonb_object_agg(type, amount) FROM by_type),
        'expense_by_cat',   (SELECT jsonb_object_agg(category, amount) FROM by_exp_cat)
    ) INTO result
    FROM rev r, exp e;
    RETURN result;
END;
$$;

-- Members expiring soon (next N days)
CREATE OR REPLACE FUNCTION get_expiring_members(p_club_id TEXT, p_days INTEGER DEFAULT 30)
RETURNS TABLE (
    member_id UUID, user_id TEXT, membership_number TEXT,
    end_date DATE, days_remaining INTEGER
) LANGUAGE sql AS $$
    SELECT id, user_id, membership_number, end_date,
           (end_date - CURRENT_DATE)::INTEGER AS days_remaining
    FROM members
    WHERE club_id = p_club_id
      AND status = 'active'
      AND end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + p_days
    ORDER BY end_date;
$$;

-- Attendance rate per session (last 30 days)
CREATE OR REPLACE FUNCTION get_session_attendance_stats(p_club_id TEXT)
RETURNS TABLE (
    session_id UUID, date DATE,
    present_count INTEGER, absent_count INTEGER, rate DECIMAL
) LANGUAGE sql AS $$
    SELECT
        a.session_id, a.date,
        COUNT(*) FILTER (WHERE is_present)::INTEGER  AS present_count,
        COUNT(*) FILTER (WHERE NOT is_present)::INTEGER AS absent_count,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_present) / NULLIF(COUNT(*),0), 1) AS rate
    FROM attendance_records a
    WHERE a.club_id = p_club_id
      AND a.date >= CURRENT_DATE - 30
    GROUP BY a.session_id, a.date
    ORDER BY a.date DESC;
$$;

-- ═══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (optionnel — activer si RLS activé)
-- ═══════════════════════════════════════════════════════════════════
-- ALTER TABLE events ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE members ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE club_expenses ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
