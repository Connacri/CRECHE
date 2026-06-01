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

drop trigger if exists daily_activities_set_updated_at
on public.daily_activities;

create trigger daily_activities_set_updated_at
before update on public.daily_activities
for each row execute function public.set_updated_at();

create index if not exists daily_activities_child_date_idx
  on public.daily_activities (child_id, date);

create index if not exists daily_activities_date_idx
  on public.daily_activities (date);

create index if not exists daily_activities_status_idx
  on public.daily_activities (status);

alter table public.daily_activities enable row level security;

create policy "Daily activities are readable by parents and course owners"
on public.daily_activities for select
to authenticated
using (
  exists (
    select 1
    from public.children ch
    where ch.id = child_id
      and ch.parent_id = (select auth.uid())::text
  )
  or exists (
    select 1
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    where e.child_id = child_id
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Daily activities are creatable by parents and course owners"
on public.daily_activities for insert
to authenticated
with check (
  exists (
    select 1
    from public.children ch
    where ch.id = child_id
      and ch.parent_id = (select auth.uid())::text
  )
  or exists (
    select 1
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    where e.child_id = child_id
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Daily activities are updatable by parents and course owners"
on public.daily_activities for update
to authenticated
using (
  exists (
    select 1
    from public.children ch
    where ch.id = child_id
      and ch.parent_id = (select auth.uid())::text
  )
  or exists (
    select 1
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    where e.child_id = child_id
      and c.created_by = (select auth.uid())::text
  )
)
with check (
  exists (
    select 1
    from public.children ch
    where ch.id = child_id
      and ch.parent_id = (select auth.uid())::text
  )
  or exists (
    select 1
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    where e.child_id = child_id
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Daily activities are deletable by parents and course owners"
on public.daily_activities for delete
to authenticated
using (
  exists (
    select 1
    from public.children ch
    where ch.id = child_id
      and ch.parent_id = (select auth.uid())::text
  )
  or exists (
    select 1
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    where e.child_id = child_id
      and c.created_by = (select auth.uid())::text
  )
);

notify pgrst, 'reload schema';
