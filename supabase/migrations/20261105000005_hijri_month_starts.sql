-- Omani Hijri calendar (spec §7): the first day of each Hijri month as
-- officially announced in Oman after local moon sighting. Entered by the
-- admin; the app falls back to Umm al-Qura for months not entered.

create table hijri_month_starts (
  hijri_year int not null check (hijri_year between 1400 and 1600),
  hijri_month smallint not null check (hijri_month between 1 and 12),
  starts_on date not null unique,
  source text not null check (char_length(source) between 3 and 300),
  primary key (hijri_year, hijri_month)
);

alter table public.hijri_month_starts enable row level security;
grant select on public.hijri_month_starts to anon, authenticated;
grant insert, update, delete on public.hijri_month_starts to authenticated;
create policy hijri_month_starts_read on public.hijri_month_starts for select to anon, authenticated
  using (true);
create policy hijri_month_starts_admin_all on public.hijri_month_starts for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
