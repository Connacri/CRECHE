create index if not exists enrollments_approved_by_idx
  on public.enrollments (approved_by);

drop policy if exists "Anyone can read active courses" on public.courses;
drop policy if exists "Course owners can read own courses" on public.courses;

create policy "Courses are readable when active or owned"
on public.courses for select
to anon, authenticated
using (
  is_active = true
  or created_by = (select auth.uid())::text
);

drop policy if exists "Course owners can manage schedules"
on public.session_schedules;

create policy "Course owners can create schedules"
on public.session_schedules for insert
to authenticated
with check (
  exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
);

create policy "Course owners can update schedules"
on public.session_schedules for update
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

create policy "Course owners can delete schedules"
on public.session_schedules for delete
to authenticated
using (
  exists (
    select 1
    from public.courses c
    where c.id = course_id
      and c.created_by = (select auth.uid())::text
  )
);
