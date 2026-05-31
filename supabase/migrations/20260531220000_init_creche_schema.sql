create extension if not exists pgcrypto;

create table if not exists public.users (
  id text primary key,
  email text not null unique,
  name text not null default '',
  role text not null default 'parent',
  profile_completed boolean not null default false,
  is_active boolean not null default true,
  deactivated_at timestamptz,
  scheduled_deletion_date timestamptz,
  profile_images jsonb not null default '{}'::jsonb,
  location jsonb,
  bio text,
  phone_number text,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_role_check check (
    role in ('parent', 'school', 'coach', 'autres')
  )
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  category text not null default 'other',
  price numeric(10, 2),
  season text not null default 'yearRound',
  season_start_date timestamptz not null,
  season_end_date timestamptz not null,
  location jsonb not null default '{}'::jsonb,
  images jsonb not null default '[]'::jsonb,
  created_by text not null references public.users(id) on delete cascade,
  is_active boolean not null default true,
  max_students integer not null default 30,
  current_students integer not null default 0,
  tags text[] not null default '{}'::text[],
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint courses_title_length_check check (char_length(trim(title)) between 3 and 200),
  constraint courses_category_check check (
    category in (
      'mathematics',
      'sciences',
      'languages',
      'arts',
      'sports',
      'technology',
      'music',
      'other'
    )
  ),
  constraint courses_season_check check (
    season in ('spring', 'summer', 'fall', 'winter', 'yearRound')
  ),
  constraint courses_price_check check (price is null or price >= 0),
  constraint courses_capacity_check check (
    max_students > 0 and current_students >= 0 and current_students <= max_students
  ),
  constraint courses_dates_check check (season_end_date >= season_start_date)
);

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  parent_id text not null references public.users(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  date_of_birth date not null,
  gender text not null default 'other',
  photo_url text,
  school_grade text,
  medical_info jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint children_gender_check check (gender in ('male', 'female', 'other'))
);

create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  parent_id text not null references public.users(id) on delete cascade,
  status text not null default 'pending',
  enrolled_at timestamptz not null default now(),
  approved_at timestamptz,
  approved_by text references public.users(id) on delete set null,
  rejection_reason text,
  payment_status text not null default 'pending',
  total_amount numeric(10, 2),
  paid_amount numeric(10, 2),
  attendance_history jsonb not null default '[]'::jsonb,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint enrollments_status_check check (
    status in ('pending', 'approved', 'rejected', 'cancelled', 'completed')
  ),
  constraint enrollments_payment_status_check check (
    payment_status in ('pending', 'partial', 'paid', 'refunded')
  ),
  constraint enrollments_amounts_check check (
    (total_amount is null or total_amount >= 0)
    and (paid_amount is null or paid_amount >= 0)
  ),
  constraint enrollments_child_course_unique unique (child_id, course_id)
);

create table if not exists public.session_schedules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  enrollment_id uuid references public.enrollments(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  time_slot jsonb not null default '{}'::jsonb,
  start_date timestamptz not null,
  end_date timestamptz not null,
  is_cancelled boolean not null default false,
  cancellation_reason text,
  current_enrollment integer not null default 0,
  max_capacity integer not null default 30,
  location text,
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

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists courses_set_updated_at on public.courses;
create trigger courses_set_updated_at
before update on public.courses
for each row execute function public.set_updated_at();

drop trigger if exists children_set_updated_at on public.children;
create trigger children_set_updated_at
before update on public.children
for each row execute function public.set_updated_at();

drop trigger if exists enrollments_set_updated_at on public.enrollments;
create trigger enrollments_set_updated_at
before update on public.enrollments
for each row execute function public.set_updated_at();

drop trigger if exists session_schedules_set_updated_at on public.session_schedules;
create trigger session_schedules_set_updated_at
before update on public.session_schedules
for each row execute function public.set_updated_at();

create index if not exists users_email_idx on public.users (email);
create index if not exists users_role_idx on public.users (role);

create index if not exists courses_created_by_idx on public.courses (created_by);
create index if not exists courses_active_created_at_idx
  on public.courses (is_active, created_at desc);
create index if not exists courses_category_season_idx
  on public.courses (category, season);
create index if not exists courses_dates_idx
  on public.courses (season_start_date, season_end_date);
create index if not exists courses_tags_gin_idx on public.courses using gin (tags);

create index if not exists children_parent_active_idx
  on public.children (parent_id, is_active);

create index if not exists enrollments_parent_idx on public.enrollments (parent_id);
create index if not exists enrollments_course_idx on public.enrollments (course_id);
create index if not exists enrollments_child_idx on public.enrollments (child_id);
create index if not exists enrollments_status_idx on public.enrollments (status);

create index if not exists session_schedules_course_idx
  on public.session_schedules (course_id);
create index if not exists session_schedules_enrollment_idx
  on public.session_schedules (enrollment_id);
create index if not exists session_schedules_day_idx
  on public.session_schedules (day_of_week);

alter table public.users enable row level security;
alter table public.courses enable row level security;
alter table public.children enable row level security;
alter table public.enrollments enable row level security;
alter table public.session_schedules enable row level security;

create policy "Users can read own profile"
on public.users for select
to authenticated
using ((select auth.uid())::text = id);

create policy "Users can create own profile"
on public.users for insert
to authenticated
with check ((select auth.uid())::text = id);

create policy "Users can update own profile"
on public.users for update
to authenticated
using ((select auth.uid())::text = id)
with check ((select auth.uid())::text = id);

create policy "Anyone can read active courses"
on public.courses for select
to anon, authenticated
using (is_active = true);

create policy "Course owners can read own courses"
on public.courses for select
to authenticated
using (created_by = (select auth.uid())::text);

create policy "Course owners can create courses"
on public.courses for insert
to authenticated
with check (created_by = (select auth.uid())::text);

create policy "Course owners can update courses"
on public.courses for update
to authenticated
using (created_by = (select auth.uid())::text)
with check (created_by = (select auth.uid())::text);

create policy "Course owners can delete courses"
on public.courses for delete
to authenticated
using (created_by = (select auth.uid())::text);

create policy "Parents can read own children"
on public.children for select
to authenticated
using (parent_id = (select auth.uid())::text);

create policy "Parents can create own children"
on public.children for insert
to authenticated
with check (parent_id = (select auth.uid())::text);

create policy "Parents can update own children"
on public.children for update
to authenticated
using (parent_id = (select auth.uid())::text)
with check (parent_id = (select auth.uid())::text);

create policy "Parents can delete own children"
on public.children for delete
to authenticated
using (parent_id = (select auth.uid())::text);

create policy "Enrollment parties can read enrollments"
on public.enrollments for select
to authenticated
using (
  parent_id = (select auth.uid())::text
  or exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Parents can create own enrollments"
on public.enrollments for insert
to authenticated
with check (
  parent_id = (select auth.uid())::text
  and exists (
    select 1
    from public.children ch
    where ch.id = child_id
      and ch.parent_id = (select auth.uid())::text
  )
);

create policy "Enrollment parties can update enrollments"
on public.enrollments for update
to authenticated
using (
  parent_id = (select auth.uid())::text
  or exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
)
with check (
  parent_id = (select auth.uid())::text
  or exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Enrollment parties can delete enrollments"
on public.enrollments for delete
to authenticated
using (
  parent_id = (select auth.uid())::text
  or exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Session parties can read schedules"
on public.session_schedules for select
to authenticated
using (
  exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
  or exists (
    select 1
    from public.enrollments e
    where e.id = enrollment_id
      and e.parent_id = (select auth.uid())::text
  )
);

create policy "Course owners can manage schedules"
on public.session_schedules for all
to authenticated
using (
  exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
)
with check (
  exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('courses', 'courses', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('user-images', 'user-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('profiles', 'profiles', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('covers', 'covers', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Anyone can read public image buckets"
on storage.objects for select
to anon, authenticated
using (bucket_id in ('courses', 'user-images', 'profiles', 'covers'));

create policy "Course owners can upload course images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'courses'
  and exists (
    select 1
    from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Course owners can update course images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'courses'
  and exists (
    select 1
    from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and c.created_by = (select auth.uid())::text
  )
)
with check (
  bucket_id = 'courses'
  and exists (
    select 1
    from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Course owners can delete course images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'courses'
  and exists (
    select 1
    from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Users can upload own profile and cover images"
on storage.objects for insert
to authenticated
with check (
  bucket_id in ('profiles', 'covers')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users can update own profile and cover images"
on storage.objects for update
to authenticated
using (
  bucket_id in ('profiles', 'covers')
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id in ('profiles', 'covers')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users can delete own profile and cover images"
on storage.objects for delete
to authenticated
using (
  bucket_id in ('profiles', 'covers')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Parents can upload child photos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'user-images'
  and exists (
    select 1
    from public.children ch
    where ch.id::text = (storage.foldername(name))[1]
      and ch.parent_id = (select auth.uid())::text
  )
);

create policy "Parents can update child photos"
on storage.objects for update
to authenticated
using (
  bucket_id = 'user-images'
  and exists (
    select 1
    from public.children ch
    where ch.id::text = (storage.foldername(name))[1]
      and ch.parent_id = (select auth.uid())::text
  )
)
with check (
  bucket_id = 'user-images'
  and exists (
    select 1
    from public.children ch
    where ch.id::text = (storage.foldername(name))[1]
      and ch.parent_id = (select auth.uid())::text
  )
);

create policy "Parents can delete child photos"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'user-images'
  and exists (
    select 1
    from public.children ch
    where ch.id::text = (storage.foldername(name))[1]
      and ch.parent_id = (select auth.uid())::text
  )
);
