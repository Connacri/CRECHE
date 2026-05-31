alter table public.users
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists address text,
  add column if not exists city text,
  add column if not exists country text,
  add column if not exists postal_code text,
  add column if not exists organization_name text,
  add column if not exists license_number text;

create or replace function public.sync_user_location_fields()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.location is not null then
    new.address = coalesce(new.address, nullif(new.location->>'address', ''));
    new.city = coalesce(new.city, nullif(new.location->>'city', ''));
    new.country = coalesce(new.country, nullif(new.location->>'country', ''));
  end if;

  if new.address is not null
      or new.city is not null
      or new.country is not null then
    new.location = coalesce(new.location, '{}'::jsonb)
      || jsonb_build_object(
        'latitude', coalesce((new.location->>'latitude')::double precision, 0.0),
        'longitude', coalesce((new.location->>'longitude')::double precision, 0.0),
        'address', coalesce(new.address, ''),
        'city', new.city,
        'country', new.country
      );
  end if;

  return new;
end;
$$;

drop trigger if exists users_sync_location_fields on public.users;
create trigger users_sync_location_fields
before insert or update on public.users
for each row execute function public.sync_user_location_fields();

create index if not exists users_city_idx on public.users (city);
create index if not exists users_organization_name_idx
  on public.users (organization_name);

notify pgrst, 'reload schema';
