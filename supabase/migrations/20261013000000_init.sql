-- OysterCatcher initial schema
-- Tables, generated PostGIS columns, RLS, views, find-or-create RPCs,
-- private photo bucket, and the anon-readable keepalive table.

create extension if not exists postgis with schema extensions;

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------
create type public.oyster_species as enum (
  'pacific', 'atlantic', 'kumamoto', 'olympia', 'european_flat'
);

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  color        text not null default '#ff6b5a'
);

-- ---------------------------------------------------------------------------
-- oysters (catalog)
-- ---------------------------------------------------------------------------
create table public.oysters (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  grower          text,
  growing_area    text,
  region          text,
  country         text default 'USA',
  species         public.oyster_species,
  cultivation     text,
  lat             numeric(9,6),
  lng             numeric(9,6),
  location        extensions.geography(Point, 4326)
    generated always as (
      case when lat is not null and lng is not null
        then extensions.st_setsrid(extensions.st_makepoint(lng, lat), 4326)::extensions.geography
      end
    ) stored,
  location_approx boolean not null default true,
  oysterater_url  text,
  notes           text,
  created_by      uuid references public.profiles (id) default auth.uid(),
  created_at      timestamptz not null default now()
);

create unique index oysters_name_grower_key
  on public.oysters (lower(name), coalesce(grower, ''));
create index oysters_location_idx on public.oysters using gist (location);

-- ---------------------------------------------------------------------------
-- places
-- ---------------------------------------------------------------------------
create table public.places (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  city       text,
  address    text,
  url        text,
  lat        numeric(9,6),
  lng        numeric(9,6),
  location   extensions.geography(Point, 4326)
    generated always as (
      case when lat is not null and lng is not null
        then extensions.st_setsrid(extensions.st_makepoint(lng, lat), 4326)::extensions.geography
      end
    ) stored,
  created_by uuid references public.profiles (id) default auth.uid(),
  created_at timestamptz not null default now()
);

create index places_location_idx on public.places using gist (location);

-- ---------------------------------------------------------------------------
-- visits (Oyster Dates)
-- ---------------------------------------------------------------------------
create table public.visits (
  id             uuid primary key default gen_random_uuid(),
  place_id       uuid references public.places (id),
  visited_on     date not null default current_date,
  notes          text,
  cover_photo_id uuid, -- FK added after photos exists
  created_by     uuid references public.profiles (id) default auth.uid(),
  created_at     timestamptz not null default now(),
  constraint visits_place_day_key unique nulls not distinct (place_id, visited_on)
);

-- ---------------------------------------------------------------------------
-- tastings
-- ---------------------------------------------------------------------------
create table public.tastings (
  id         uuid primary key default gen_random_uuid(),
  visit_id   uuid not null references public.visits (id) on delete cascade,
  oyster_id  uuid not null references public.oysters (id),
  price_each numeric(6,2),
  created_by uuid references public.profiles (id) default auth.uid(),
  created_at timestamptz not null default now(),
  constraint tastings_visit_oyster_key unique (visit_id, oyster_id)
);

create index tastings_oyster_idx on public.tastings (oyster_id);

-- ---------------------------------------------------------------------------
-- ratings
-- ---------------------------------------------------------------------------
create table public.ratings (
  id                uuid primary key default gen_random_uuid(),
  tasting_id        uuid not null references public.tastings (id) on delete cascade,
  user_id           uuid not null references public.profiles (id) default auth.uid(),
  overall           smallint check (overall between 1 and 5),
  brininess         smallint check (brininess between 1 and 5),
  sweetness         smallint check (sweetness between 1 and 5),
  creaminess        smallint check (creaminess between 1 and 5),
  minerality        smallint check (minerality between 1 and 5),
  brightness        smallint check (brightness between 1 and 5),
  texture           smallint check (texture between 1 and 5),
  size              smallint check (size between 1 and 5),
  would_order_again boolean,
  note              text,
  updated_at        timestamptz not null default now(),
  constraint ratings_tasting_user_key unique (tasting_id, user_id)
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger ratings_touch before update on public.ratings
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- photos
-- ---------------------------------------------------------------------------
create table public.photos (
  id           uuid primary key default gen_random_uuid(),
  visit_id     uuid not null references public.visits (id) on delete cascade,
  tasting_id   uuid references public.tastings (id) on delete set null,
  storage_path text not null,
  thumb_path   text not null,
  taken_by     uuid references public.profiles (id) default auth.uid(),
  created_at   timestamptz not null default now()
);

create index photos_visit_idx on public.photos (visit_id);
create index photos_tasting_idx on public.photos (tasting_id);

alter table public.visits
  add constraint visits_cover_photo_fk
  foreign key (cover_photo_id) references public.photos (id) on delete set null;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.oysters  enable row level security;
alter table public.places   enable row level security;
alter table public.visits   enable row level security;
alter table public.tastings enable row level security;
alter table public.ratings  enable row level security;
alter table public.photos   enable row level security;

create policy "profiles: read" on public.profiles
  for select to authenticated using (true);
create policy "profiles: update self" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Shared-fact tables: everyone signed in can read/insert/update; delete only your own.
do $$
declare t text;
begin
  foreach t in array array['oysters', 'places', 'visits', 'tastings'] loop
    execute format('create policy "%1$s: read" on public.%1$I for select to authenticated using (true)', t);
    execute format('create policy "%1$s: insert" on public.%1$I for insert to authenticated with check (true)', t);
    execute format('create policy "%1$s: update" on public.%1$I for update to authenticated using (true) with check (true)', t);
    execute format('create policy "%1$s: delete own" on public.%1$I for delete to authenticated using (created_by = auth.uid())', t);
  end loop;
end $$;

create policy "photos: read" on public.photos
  for select to authenticated using (true);
create policy "photos: insert" on public.photos
  for insert to authenticated with check (true);
create policy "photos: update" on public.photos
  for update to authenticated using (true) with check (true);
create policy "photos: delete own" on public.photos
  for delete to authenticated using (taken_by = auth.uid());

create policy "ratings: read" on public.ratings
  for select to authenticated using (true);
create policy "ratings: insert own" on public.ratings
  for insert to authenticated with check (user_id = auth.uid());
create policy "ratings: update own" on public.ratings
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "ratings: delete own" on public.ratings
  for delete to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Find-or-create RPCs
-- The client generates ids; if a row already exists for the natural key, the
-- server's id comes back and the client remaps any queued children to it.
-- security invoker, so RLS still applies.
-- ---------------------------------------------------------------------------
create or replace function public.find_or_create_visit(
  p_id uuid, p_place_id uuid, p_visited_on date, p_notes text default null
) returns uuid
language plpgsql security invoker set search_path = public as $$
declare v_id uuid;
begin
  insert into visits (id, place_id, visited_on, notes)
  values (p_id, p_place_id, p_visited_on, p_notes)
  on conflict on constraint visits_place_day_key do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id from visits
    where place_id is not distinct from p_place_id and visited_on = p_visited_on;
  end if;
  return v_id;
end $$;

create or replace function public.find_or_create_tasting(
  p_id uuid, p_visit_id uuid, p_oyster_id uuid, p_price_each numeric default null
) returns uuid
language plpgsql security invoker set search_path = public as $$
declare v_id uuid;
begin
  insert into tastings (id, visit_id, oyster_id, price_each)
  values (p_id, p_visit_id, p_oyster_id, p_price_each)
  on conflict on constraint tastings_visit_oyster_key do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id from tastings
    where visit_id = p_visit_id and oyster_id = p_oyster_id;
    if p_price_each is not null then
      update tastings set price_each = p_price_each where id = v_id and price_each is null;
    end if;
  end if;
  return v_id;
end $$;

create or replace function public.find_or_create_oyster(
  p_id uuid, p_name text, p_grower text default null, p_growing_area text default null,
  p_species public.oyster_species default null, p_lat numeric default null, p_lng numeric default null
) returns uuid
language plpgsql security invoker set search_path = public as $$
declare v_id uuid;
begin
  select id into v_id from oysters
  where lower(name) = lower(p_name) and coalesce(grower, '') = coalesce(p_grower, '');
  if v_id is not null then
    return v_id;
  end if;

  insert into oysters (id, name, grower, growing_area, species, lat, lng, location_approx)
  values (p_id, p_name, p_grower, p_growing_area, p_species, p_lat, p_lng, p_lat is null)
  returning id into v_id;
  return v_id;
exception when unique_violation then
  select id into v_id from oysters
  where lower(name) = lower(p_name) and coalesce(grower, '') = coalesce(p_grower, '');
  return v_id;
end $$;

grant execute on function public.find_or_create_visit   to authenticated;
grant execute on function public.find_or_create_tasting to authenticated;
grant execute on function public.find_or_create_oyster  to authenticated;
revoke execute on function public.find_or_create_visit   from anon, public;
revoke execute on function public.find_or_create_tasting from anon, public;
revoke execute on function public.find_or_create_oyster  from anon, public;

-- ---------------------------------------------------------------------------
-- Views (security_invoker so RLS of the caller applies)
-- ---------------------------------------------------------------------------
create view public.oyster_stats with (security_invoker = true) as
select
  t.oyster_id,
  r.user_id,
  round(avg(r.overall)::numeric, 2)                              as avg_overall,
  round(avg(r.brininess)::numeric, 2)                            as avg_brininess,
  round(avg(r.sweetness)::numeric, 2)                            as avg_sweetness,
  round(avg(r.creaminess)::numeric, 2)                           as avg_creaminess,
  round(avg(r.minerality)::numeric, 2)                           as avg_minerality,
  round(avg(r.brightness)::numeric, 2)                           as avg_brightness,
  round(avg(r.texture)::numeric, 2)                              as avg_texture,
  round(avg(r.size)::numeric, 2)                                 as avg_size,
  count(*)::int                                                  as tasting_count,
  max(v.visited_on)                                              as last_tasted,
  round(100.0 * avg(case when r.would_order_again then 1.0
                         when r.would_order_again = false then 0.0 end), 0) as would_order_again_pct
from public.ratings r
join public.tastings t on t.id = r.tasting_id
join public.visits v   on v.id = t.visit_id
group by t.oyster_id, r.user_id;

create view public.oyster_stats_combined with (security_invoker = true) as
select
  o.id                                                 as oyster_id,
  o.name,
  o.grower,
  o.growing_area,
  o.region,
  o.species,
  o.lat,
  o.lng,
  o.location_approx,
  round(avg(r.overall)::numeric, 2)                    as avg_overall,
  count(distinct t.id)::int                            as tasting_count,
  max(v.visited_on)                                    as last_tasted,
  round(100.0 * avg(case when r.would_order_again then 1.0
                         when r.would_order_again = false then 0.0 end), 0) as would_order_again_pct
from public.oysters o
left join public.tastings t on t.oyster_id = o.id
left join public.visits v   on v.id = t.visit_id
left join public.ratings r  on r.tasting_id = t.id
group by o.id;

create view public.visit_summary with (security_invoker = true) as
select
  v.id,
  v.place_id,
  v.visited_on,
  v.notes,
  v.cover_photo_id,
  v.created_by,
  v.created_at,
  p.name                                                   as place_name,
  p.city                                                   as place_city,
  p.lat                                                    as place_lat,
  p.lng                                                    as place_lng,
  ph.thumb_path                                            as cover_thumb_path,
  ph.storage_path                                          as cover_storage_path,
  (select count(*)::int from public.tastings t where t.visit_id = v.id) as tasting_count,
  (
    select coalesce(jsonb_object_agg(x.user_id, x.avg_overall), '{}'::jsonb)
    from (
      select r.user_id, round(avg(r.overall)::numeric, 2) as avg_overall
      from public.ratings r
      join public.tastings t on t.id = r.tasting_id
      where t.visit_id = v.id and r.overall is not null
      group by r.user_id
    ) x
  )                                                        as avg_overall_by_user
from public.visits v
left join public.places p  on p.id = v.place_id
left join public.photos ph on ph.id = v.cover_photo_id;

grant select on public.oyster_stats, public.oyster_stats_combined, public.visit_summary to authenticated;

-- ---------------------------------------------------------------------------
-- Storage: private "photos" bucket
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;

create policy "photos bucket: read" on storage.objects
  for select to authenticated using (bucket_id = 'photos');
create policy "photos bucket: insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'photos');
create policy "photos bucket: update" on storage.objects
  for update to authenticated using (bucket_id = 'photos') with check (bucket_id = 'photos');
create policy "photos bucket: delete own" on storage.objects
  for delete to authenticated using (bucket_id = 'photos' and owner_id = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- Keepalive: a tiny table the anon key may read, so the daily ping touches
-- the database without exposing any real data.
-- ---------------------------------------------------------------------------
create table public.keepalive (
  id      int primary key,
  pinged  text not null default 'shuck yeah'
);
insert into public.keepalive (id) values (1);
alter table public.keepalive enable row level security;
create policy "keepalive: anon read" on public.keepalive
  for select to anon, authenticated using (true);
grant select on public.keepalive to anon;
