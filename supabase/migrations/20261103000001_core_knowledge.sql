-- Core knowledge schema (Phase 1). Runs unchanged on Supabase: relies on the
-- platform-provided auth.users / auth.uid() and creates no roles.

create type knowledge_status as enum ('draft', 'reviewed', 'published');
create type crop_category as enum (
  'vegetable', 'fruit', 'legume', 'cereal', 'forage', 'ornamental', 'medicinal_aromatic', 'tree');
create type lifecycle as enum ('annual', 'perennial', 'tree');
create type source_type as enum ('ministry', 'university', 'fao', 'peer_reviewed', 'dataset', 'other');
create type user_role as enum ('farmer', 'shop', 'admin');
create type growth_stage as enum ('initial', 'development', 'mid', 'late');
create type soil_texture as enum ('sand', 'loam', 'clay');

create table sources (
  id text primary key,
  title text not null,
  publisher text not null,
  year int,
  url text,
  type source_type not null,
  reliability smallint check (reliability between 1 and 3)
);

create table governorates (
  id text primary key,
  name_ar text not null,
  name_en text not null,
  status knowledge_status not null default 'draft',
  source_id text not null references sources(id),
  source_page text,
  reviewed_by text,
  reviewed_at timestamptz,
  constraint governorates_published_reviewed check (status <> 'published' or (reviewed_by is not null and reviewed_at is not null))
);

create table wilayats (
  id text primary key,
  governorate_id text not null references governorates(id),
  name_ar text not null,
  name_en text not null,
  status knowledge_status not null default 'draft',
  source_id text not null references sources(id),
  source_page text,
  reviewed_by text,
  reviewed_at timestamptz,
  constraint wilayats_published_reviewed check (status <> 'published' or (reviewed_by is not null and reviewed_at is not null))
);

create table crops (
  id text primary key,
  name_ar text not null,
  name_en text not null,
  scientific_name text,
  categories crop_category[] not null check (cardinality(categories) >= 1),
  lifecycle lifecycle,
  notes_ar text,
  notes_en text,
  status knowledge_status not null default 'draft',
  source_id text not null references sources(id),
  source_page text,
  reviewed_by text,
  reviewed_at timestamptz,
  constraint crops_published_reviewed check (status <> 'published' or (reviewed_by is not null and reviewed_at is not null))
);

create table crop_requirements (
  crop_id text primary key references crops(id) on delete cascade,
  t_min numeric,
  t_opt_low numeric,
  t_opt_high numeric,
  t_max numeric,
  chill_hours_min int,
  ece_threshold numeric,
  ece_slope numeric,
  ph_min numeric,
  ph_max numeric,
  textures soil_texture[],
  alt_min int,
  alt_max int,
  season_days_min int,
  season_days_max int,
  status knowledge_status not null default 'draft',
  source_id text not null references sources(id),
  source_page text,
  reviewed_by text,
  reviewed_at timestamptz,
  constraint crop_requirements_published_reviewed check (status <> 'published' or (reviewed_by is not null and reviewed_at is not null)),
  constraint crop_requirements_temp_order check (
    t_min <= t_opt_low and t_opt_low <= t_opt_high and t_opt_high <= t_max)
);

create table crop_stages (
  crop_id text not null references crops(id) on delete cascade,
  seq smallint not null,
  stage growth_stage not null,
  duration_days int not null check (duration_days > 0),
  kc numeric not null check (kc between 0 and 1.5),
  status knowledge_status not null default 'draft',
  source_id text not null references sources(id),
  source_page text,
  reviewed_by text,
  reviewed_at timestamptz,
  constraint crop_stages_published_reviewed check (status <> 'published' or (reviewed_by is not null and reviewed_at is not null)),
  primary key (crop_id, seq)
);

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'farmer',
  display_name text
);

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
