-- ── INVENTORY ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    sku TEXT,
    unit_price DECIMAL(10,2) DEFAULT 0,
    sale_price DECIMAL(10,2) DEFAULT 0,
    quantity_in_stock INTEGER DEFAULT 0,
    min_quantity_alert INTEGER DEFAULT 5,
    supplier_info JSONB DEFAULT '{}',
    images JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    club_id TEXT NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('stock_in', 'stock_out', 'sale', 'adjustment', 'return')),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    related_invoice_id UUID REFERENCES public.invoices(id) ON DELETE SET NULL,
    notes TEXT,
    created_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to update quantity_in_stock
CREATE OR REPLACE FUNCTION update_inventory_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF NEW.transaction_type IN ('stock_in', 'return') THEN
            UPDATE public.inventory_items
            SET quantity_in_stock = quantity_in_stock + NEW.quantity, updated_at = NOW()
            WHERE id = NEW.item_id;
        ELSIF NEW.transaction_type IN ('stock_out', 'sale', 'adjustment') THEN
            UPDATE public.inventory_items
            SET quantity_in_stock = quantity_in_stock - NEW.quantity, updated_at = NOW()
            WHERE id = NEW.item_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_inventory_stock
AFTER INSERT ON public.inventory_transactions
FOR EACH ROW EXECUTE FUNCTION update_inventory_stock();

-- ── MEMBERSHIPS / SUBSCRIPTIONS ENHANCEMENTS ───────────────────────
-- Ensure members table is robust for subscriptions
ALTER TABLE public.members ADD COLUMN IF NOT EXISTS current_plan_id UUID REFERENCES public.membership_plans(id);
ALTER TABLE public.members ADD COLUMN IF NOT EXISTS auto_renew BOOLEAN DEFAULT false;

-- RPC to get expiring/expired subscriptions
CREATE OR REPLACE FUNCTION get_club_subscription_status(p_club_id TEXT)
RETURNS TABLE (
    total_active_members BIGINT,
    expiring_soon BIGINT,
    recently_expired BIGINT,
    total_revenue_members DECIMAL
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE status = 'active') as total_active_members,
        COUNT(*) FILTER (WHERE status = 'active' AND end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days') as expiring_soon,
        COUNT(*) FILTER (WHERE status = 'expired' AND end_date >= CURRENT_DATE - INTERVAL '30 days') as recently_expired,
        COALESCE(SUM(paid_amount) FILTER (WHERE type = 'subscription'), 0) as total_revenue_members
    FROM public.members m
    LEFT JOIN public.invoices i ON i.member_id = m.id AND i.club_id = p_club_id
    WHERE m.club_id = p_club_id;
END;
$$;

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
