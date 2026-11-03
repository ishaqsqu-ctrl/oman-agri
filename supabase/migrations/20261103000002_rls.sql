-- Row-level security and admin publish RPC (Phase 1). Runs unchanged on
-- Supabase: references anon/authenticated only in GRANT/policy clauses.

create function public.is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  );
$$;

-- Policies of anon and authenticated call it, so both keep execute.
revoke execute on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- NOTE: Supabase already grants all privileges on public objects to anon and
-- authenticated via default privileges, so the grants below are redundant there
-- (kept for plain Postgres). RLS is the security boundary, never the grants.

-- Knowledge tables: published rows readable by everyone, admin does everything.
do $$
declare
  t text;
begin
  foreach t in array array['governorates', 'wilayats', 'crops', 'crop_requirements', 'crop_stages']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('grant select on public.%I to anon, authenticated', t);
    execute format('grant insert, update, delete on public.%I to authenticated', t);
    execute format(
      'create policy %I on public.%I for select to anon, authenticated using (status = ''published'')',
      t || '_read_published', t);
    execute format(
      'create policy %I on public.%I for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()))',
      t || '_admin_all', t);
  end loop;
end;
$$;

-- Sources: always readable (they back the "Source" affordance); admin writes.
alter table public.sources enable row level security;
grant select on public.sources to anon, authenticated;
grant insert, update, delete on public.sources to authenticated;
create policy sources_read on public.sources for select to anon, authenticated using (true);
create policy sources_admin_all on public.sources for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Profiles: users read/update their own row; admin everything. Role/id
-- changes by non-admins are stopped by a trigger (grants are not a guard).
alter table public.profiles enable row level security;
grant select, update on public.profiles to authenticated;
create policy profiles_select_own on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy profiles_admin_all on public.profiles for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Deliberately SECURITY INVOKER: current_user must be the calling API role
-- (inside SECURITY DEFINER it would be the owner). It only guards the API
-- roles anon/authenticated, so owner/service_role/migrations (direct SQL) pass.
create function public.guard_profile_privileged_columns() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated')
     and (new.role is distinct from old.role or new.id is distinct from old.id)
     and not public.is_admin() then
    raise exception 'role and id can only be changed by an admin'
      using errcode = 'insufficient_privilege';
  end if;
  return new;
end;
$$;

create trigger profiles_guard_privileged_columns
  before update on public.profiles
  for each row execute function public.guard_profile_privileged_columns();

-- Admin RPCs.
create function public.publish_reviewed(p_table text) returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  n integer;
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = 'insufficient_privilege';
  end if;
  if p_table is null
     or p_table <> all (array['governorates', 'wilayats', 'crops', 'crop_requirements', 'crop_stages']) then
    raise exception 'unknown knowledge table: %', p_table using errcode = 'invalid_parameter_value';
  end if;
  execute format(
    'update public.%I set status = ''published'' where status = ''reviewed''', p_table);
  get diagnostics n = row_count;
  return n;
end;
$$;

create function public.knowledge_status_counts()
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
    union all select 'crop_stages', x.status, count(*) from public.crop_stages x group by x.status;
end;
$$;

revoke execute on function public.publish_reviewed(text) from public, anon;
revoke execute on function public.knowledge_status_counts() from public, anon;
grant execute on function public.publish_reviewed(text) to authenticated;
grant execute on function public.knowledge_status_counts() to authenticated;
