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

revoke execute on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

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
      'create policy %I on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())',
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
  using (public.is_admin()) with check (public.is_admin());

-- Profiles: own row only; the column grant (display_name only) is what stops
-- role self-promotion. Role changes go through the service role / SQL.
alter table public.profiles enable row level security;
grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;
create policy profiles_select_own on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

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

revoke execute on function public.publish_reviewed(text) from public;
revoke execute on function public.knowledge_status_counts() from public;
grant execute on function public.publish_reviewed(text) to authenticated;
grant execute on function public.knowledge_status_counts() to authenticated;
