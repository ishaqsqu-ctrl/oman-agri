-- Test-only shims mirroring what Supabase provides. NEVER ship in migrations.
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users (id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as
$$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to anon, authenticated;
grant usage on schema public to anon, authenticated;
-- Mirror Supabase's default privileges: every object the migrations create in
-- public is fully granted to anon/authenticated, so RLS (not grants) is the
-- security boundary.
alter default privileges for role postgres in schema public grant all on tables to anon, authenticated;
alter default privileges for role postgres in schema public grant all on functions to anon, authenticated;
alter default privileges for role postgres in schema public grant all on sequences to anon, authenticated;
