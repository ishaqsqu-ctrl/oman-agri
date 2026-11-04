-- Monthly crop coefficients for perennial crops (trees, palms), where FAO-56's
-- four-stage curve does not fit. One row per crop and calendar month; a source
-- that gives one annual value is stored as the same kc in every month it covers.

create table crop_kc_monthly (
  crop_id text not null references crops(id) on delete cascade,
  month smallint not null check (month between 1 and 12),
  kc numeric not null check (kc between 0 and 1.5),
  status knowledge_status not null default 'draft',
  source_id text not null references sources(id),
  source_page text,
  reviewed_by text,
  reviewed_at timestamptz,
  constraint crop_kc_monthly_published_reviewed check (status <> 'published' or (reviewed_by is not null and reviewed_at is not null)),
  primary key (crop_id, month)
);

-- Same access rules as the other knowledge tables (see 20261103000002_rls.sql).
alter table public.crop_kc_monthly enable row level security;
grant select on public.crop_kc_monthly to anon, authenticated;
grant insert, update, delete on public.crop_kc_monthly to authenticated;
create policy crop_kc_monthly_read_published on public.crop_kc_monthly for select to anon, authenticated
  using (status = 'published');
create policy crop_kc_monthly_admin_all on public.crop_kc_monthly for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Admin RPCs learn the new table. CREATE OR REPLACE keeps existing grants.
create or replace function public.publish_reviewed(p_table text) returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  n integer;
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = 'insufficient_privilege';
  end if;
  if p_table is null
     or p_table <> all (array['governorates', 'wilayats', 'crops', 'crop_requirements', 'crop_stages', 'crop_kc_monthly']) then
    raise exception 'unknown knowledge table: %', p_table using errcode = 'invalid_parameter_value';
  end if;
  execute format(
    'update public.%I set status = ''published'' where status = ''reviewed''', p_table);
  get diagnostics n = row_count;
  return n;
end;
$$;

create or replace function public.knowledge_status_counts()
returns table(table_name text, status public.knowledge_status, n bigint)
language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = 'insufficient_privilege';
  end if;
  return query
    select 'governorates', x.status, count(*) from public.governorates x group by x.status
    union all select 'wilayats', x.status, count(*) from public.wilayats x group by x.status
    union all select 'crops', x.status, count(*) from public.crops x group by x.status
    union all select 'crop_requirements', x.status, count(*) from public.crop_requirements x group by x.status
    union all select 'crop_stages', x.status, count(*) from public.crop_stages x group by x.status
    union all select 'crop_kc_monthly', x.status, count(*) from public.crop_kc_monthly x group by x.status;
end;
$$;
