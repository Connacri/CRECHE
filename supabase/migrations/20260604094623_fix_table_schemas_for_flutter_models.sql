-- =====================================================================
-- Migration: Fix table schemas to match Flutter models
-- Drops and recreates tables that have incorrect column definitions
-- =====================================================================

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: Drop dependent tables first (they reference session_schedules)
-- ═══════════════════════════════════════════════════════════════════
drop table if exists public.qr_attendance_tokens cascade;
drop table if exists public.attendance_records cascade;

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: Drop tables with incorrect schemas
-- ═══════════════════════════════════════════════════════════════════
drop table if exists public.session_schedules cascade;
drop table if exists public.daily_activities cascade;
drop table if exists public.school_available_slots cascade;

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: Recreate session_schedules to match migration + model
-- ═══════════════════════════════════════════════════════════════════
create table if not exists public.session_schedules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  enrollment_id uuid references public.enrollments(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  time_slot jsonb not null default '{}'::jsonb,
  start_date timestamptz not null default now(),
  end_date timestamptz not null default now(),
  is_cancelled boolean not null default false,
  cancellation_reason text,
  current_enrollment integer not null default 0,
  max_capacity integer not null default 30,
  location text,
  coach_id text,
  room_name text,
  school_id text,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint session_schedules_capacity_check check (
    max_capacity > 0
    and current_enrollment >= 0
    and current_enrollment <= max_capacity
  ),
  constraint session_schedules_dates_check check (end_date >= start_date)
);

drop trigger if exists session_schedules_set_updated_at on public.session_schedules;
create trigger session_schedules_set_updated_at
before update on public.session_schedules
for each row execute function public.set_updated_at();

create index if not exists session_schedules_course_idx on public.session_schedules (course_id);
create index if not exists session_schedules_enrollment_idx on public.session_schedules (enrollment_id);
create index if not exists session_schedules_day_idx on public.session_schedules (day_of_week);
create index if not exists session_schedules_school_id_idx on public.session_schedules (school_id);

alter table public.session_schedules enable row level security;

drop policy if exists "Session parties can read schedules" on public.session_schedules;
create policy "Session parties can read schedules"
on public.session_schedules for select
to anon, authenticated
using (
  exists (
    select 1 from public.courses c
    where c.id = course_id and c.created_by = get_firebase_uid()
  )
  or exists (
    select 1 from public.enrollments e
    where e.id = enrollment_id and e.parent_id = get_firebase_uid()
  )
);

drop policy if exists "Course owners can create schedules" on public.session_schedules;
create policy "Course owners can create schedules"
on public.session_schedules for insert
to anon, authenticated
with check (
  exists (
    select 1 from public.courses c
    where c.id = course_id and c.created_by = get_firebase_uid()
  )
);

drop policy if exists "Course owners can update schedules" on public.session_schedules;
create policy "Course owners can update schedules"
on public.session_schedules for update
to anon, authenticated
using (
  exists (
    select 1 from public.courses c
    where c.id = course_id and c.created_by = get_firebase_uid()
  )
)
with check (
  exists (
    select 1 from public.courses c
    where c.id = course_id and c.created_by = get_firebase_uid()
  )
);

drop policy if exists "Course owners can delete schedules" on public.session_schedules;
create policy "Course owners can delete schedules"
on public.session_schedules for delete
to anon, authenticated
using (
  exists (
    select 1 from public.courses c
    where c.id = course_id and c.created_by = get_firebase_uid()
  )
);

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: Recreate daily_activities to match migration + model
-- ═══════════════════════════════════════════════════════════════════
create table if not exists public.daily_activities (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  date date not null,
  type text not null default 'other',
  title text not null,
  description text,
  status text not null default 'pending',
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint daily_activities_type_check check (
    type in ('meal', 'activity', 'task', 'nap', 'other')
  ),
  constraint daily_activities_status_check check (
    status in ('pending', 'completed', 'cancelled', 'skipped')
  ),
  constraint daily_activities_title_length_check check (
    char_length(trim(title)) between 1 and 200
  )
);

drop trigger if exists daily_activities_set_updated_at on public.daily_activities;
create trigger daily_activities_set_updated_at
before update on public.daily_activities
for each row execute function public.set_updated_at();

create index if not exists daily_activities_child_date_idx on public.daily_activities (child_id, date);
create index if not exists daily_activities_date_idx on public.daily_activities (date);
create index if not exists daily_activities_status_idx on public.daily_activities (status);

alter table public.daily_activities enable row level security;

drop policy if exists "Daily activities are readable by parents and course owners" on public.daily_activities;
create policy "Daily activities are readable by parents and course owners"
on public.daily_activities for select
to anon, authenticated
using (
  exists (select 1 from public.children ch where ch.id = child_id and ch.parent_id = get_firebase_uid())
  or exists (select 1 from public.enrollments e join public.courses c on c.id = e.course_id where e.child_id = child_id and c.created_by = get_firebase_uid())
);

drop policy if exists "Daily activities are creatable by parents and course owners" on public.daily_activities;
create policy "Daily activities are creatable by parents and course owners"
on public.daily_activities for insert
to anon, authenticated
with check (
  exists (select 1 from public.children ch where ch.id = child_id and ch.parent_id = get_firebase_uid())
  or exists (select 1 from public.enrollments e join public.courses c on c.id = e.course_id where e.child_id = child_id and c.created_by = get_firebase_uid())
);

drop policy if exists "Daily activities are updatable by parents and course owners" on public.daily_activities;
create policy "Daily activities are updatable by parents and course owners"
on public.daily_activities for update
to anon, authenticated
using (
  exists (select 1 from public.children ch where ch.id = child_id and ch.parent_id = get_firebase_uid())
  or exists (select 1 from public.enrollments e join public.courses c on c.id = e.course_id where e.child_id = child_id and c.created_by = get_firebase_uid())
)
with check (
  exists (select 1 from public.children ch where ch.id = child_id and ch.parent_id = get_firebase_uid())
  or exists (select 1 from public.enrollments e join public.courses c on c.id = e.course_id where e.child_id = child_id and c.created_by = get_firebase_uid())
);

drop policy if exists "Daily activities are deletable by parents and course owners" on public.daily_activities;
create policy "Daily activities are deletable by parents and course owners"
on public.daily_activities for delete
to anon, authenticated
using (
  exists (select 1 from public.children ch where ch.id = child_id and ch.parent_id = get_firebase_uid())
  or exists (select 1 from public.enrollments e join public.courses c on c.id = e.course_id where e.child_id = child_id and c.created_by = get_firebase_uid())
);

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5: Recreate school_available_slots to match migration + model
-- ═══════════════════════════════════════════════════════════════════
create table if not exists public.school_available_slots (
  id uuid primary key default gen_random_uuid(),
  school_id text not null,
  day_of_week integer not null check (day_of_week between 0 and 6),
  time_slot jsonb not null default '{}'::jsonb,
  is_occupied boolean not null default false,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists school_available_slots_school_idx on public.school_available_slots (school_id);
create index if not exists school_available_slots_day_idx on public.school_available_slots (day_of_week);

alter table public.school_available_slots enable row level security;

drop policy if exists "Schools can manage own slots" on public.school_available_slots;
create policy "Schools can manage own slots"
on public.school_available_slots for all
to anon, authenticated
using (school_id = get_firebase_uid())
with check (school_id = get_firebase_uid());

drop policy if exists "Anyone authenticated can view school slots" on public.school_available_slots;
create policy "Anyone authenticated can view school slots"
on public.school_available_slots for select
to anon, authenticated
using (true);

-- ═══════════════════════════════════════════════════════════════════
-- STEP 6: Recreate attendance_records (same schema as before)
-- ═══════════════════════════════════════════════════════════════════
create table if not exists public.attendance_records (
    id uuid primary key default gen_random_uuid(),
    club_id text not null,
    session_id uuid references public.session_schedules(id),
    enrollment_id uuid references public.enrollments(id),
    child_id uuid references public.children(id),
    member_id uuid references public.members(id),
    date date not null,
    check_in_time timestamptz,
    check_out_time timestamptz,
    method text default 'manual' check (method in ('manual','qr_code','gps','nfc')),
    is_present boolean default true,
    is_late boolean default false,
    check_in_lat decimal(10,8),
    check_in_lng decimal(11,8),
    qr_token text,
    notes text,
    recorded_by text,
    created_at timestamptz default now()
);

create index if not exists idx_attendance_session_id on public.attendance_records(session_id);
create index if not exists idx_attendance_date on public.attendance_records(date);
create index if not exists idx_attendance_club_id on public.attendance_records(club_id);

-- ═══════════════════════════════════════════════════════════════════
-- STEP 7: Recreate qr_attendance_tokens (same schema as before)
-- ═══════════════════════════════════════════════════════════════════
create table if not exists public.qr_attendance_tokens (
    id uuid primary key default gen_random_uuid(),
    club_id text not null,
    session_id uuid references public.session_schedules(id),
    token text not null unique default gen_random_uuid()::text,
    date date not null default current_date,
    expires_at timestamptz not null,
    scans_count integer default 0,
    is_active boolean default true,
    created_at timestamptz default now()
);

notify pgrst, 'reload schema';