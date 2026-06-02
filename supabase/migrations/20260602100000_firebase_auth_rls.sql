-- Migration to adapt RLS for Firebase Auth integration
-- This migration replaces auth.uid() with a custom function that can read a Firebase UID
-- passed via a custom header 'x-firebase-id'.

-- 1. Create a function to get the current Firebase User ID
create or replace function public.get_firebase_uid()
returns text
language sql stable
as $$
  -- Extracts the Firebase UID from the 'x-firebase-id' header.
  -- In production, you should ideally verify a JWT token instead of a raw ID.
  select nullif(current_setting('request.headers', true)::json->>'x-firebase-id', '')::text;
$$;

-- 2. Update existing policies to use get_firebase_uid() and allow 'anon' role
-- Since Firebase users are not authenticated via Supabase Auth, they appear as 'anon'.

-- Drop existing policies first to recreate them
do $$
declare
    pol record;
begin
    for pol in (
        select policyname, tablename 
        from pg_policies 
        where schemaname = 'public' 
          and (policyname like '%own%' or policyname like '%parties%' or policyname like '%owners%')
    ) loop
        execute format('drop policy %I on %I', pol.policyname, pol.tablename);
    end loop;
end $$;

-- --- USERS TABLE ---
create policy "Users can read own profile"
on public.users for select
to anon, authenticated
using (get_firebase_uid() = id);

create policy "Users can create own profile"
on public.users for insert
to anon, authenticated
with check (get_firebase_uid() = id);

create policy "Users can update own profile"
on public.users for update
to anon, authenticated
using (get_firebase_uid() = id)
with check (get_firebase_uid() = id);

-- --- COURSES TABLE ---
create policy "Course owners can read own courses"
on public.courses for select
to anon, authenticated
using (created_by = get_firebase_uid());

create policy "Course owners can create courses"
on public.courses for insert
to anon, authenticated
with check (created_by = get_firebase_uid());

create policy "Course owners can update courses"
on public.courses for update
to anon, authenticated
using (created_by = get_firebase_uid())
with check (created_by = get_firebase_uid());

create policy "Course owners can delete courses"
on public.courses for delete
to anon, authenticated
using (created_by = get_firebase_uid());

-- --- CHILDREN TABLE ---
create policy "Parents can read own children"
on public.children for select
to anon, authenticated
using (parent_id = get_firebase_uid());

create policy "Parents can create own children"
on public.children for insert
to anon, authenticated
with check (parent_id = get_firebase_uid());

create policy "Parents can update own children"
on public.children for update
to anon, authenticated
using (parent_id = get_firebase_uid())
with check (parent_id = get_firebase_uid());

create policy "Parents can delete own children"
on public.children for delete
to anon, authenticated
using (parent_id = get_firebase_uid());

-- --- ENROLLMENTS TABLE ---
create policy "Enrollment parties can read enrollments"
on public.enrollments for select
to anon, authenticated
using (
  parent_id = get_firebase_uid()
  or exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = get_firebase_uid()
  )
);

create policy "Parents can create own enrollments"
on public.enrollments for insert
to anon, authenticated
with check (
  parent_id = get_firebase_uid()
  and exists (
    select 1
    from public.children ch
    where ch.id = child_id
      and ch.parent_id = get_firebase_uid()
  )
);

create policy "Enrollment parties can update enrollments"
on public.enrollments for update
to anon, authenticated
using (
  parent_id = get_firebase_uid()
  or exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = get_firebase_uid()
  )
)
with check (
  parent_id = get_firebase_uid()
  or exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = get_firebase_uid()
  )
);

-- --- STORAGE POLICIES (Update these in a similar fashion if needed) ---
-- Note: Storage RLS also supports anon if configured correctly.
-- Re-applying storage policies using get_firebase_uid()

create policy "Course owners can upload course images v2"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id = 'courses'
  and exists (
    select 1
    from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and c.created_by = get_firebase_uid()
  )
);

create policy "Users can upload own profile and cover images v2"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id in ('profiles', 'covers')
  and (storage.foldername(name))[1] = get_firebase_uid()
);

create policy "Parents can upload child photos v2"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id = 'user-images'
  and exists (
    select 1
    from public.children ch
    where ch.id::text = (storage.foldername(name))[1]
      and ch.parent_id = get_firebase_uid()
  )
);
