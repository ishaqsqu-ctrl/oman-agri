-- Store (spec §2 item 7, §5.4 "المتجر"): shops that register themselves, are
-- approved by the admin, and list their products with prices. Farmers contact
-- the shop directly (phone / WhatsApp); ordering comes later.

create type shop_status as enum ('pending', 'approved', 'suspended');
create type product_category as enum (
  'seeds', 'seedlings', 'fertilizer', 'pesticide', 'irrigation', 'tools', 'other');

create table shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  wilayat_id text not null references wilayats(id),
  phone text not null check (phone ~ '^\+?[0-9 ]{7,16}$'),
  whatsapp text check (whatsapp is null or whatsapp ~ '^\+?[0-9 ]{7,16}$'),
  address text check (address is null or char_length(address) <= 200),
  status shop_status not null default 'pending',
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);
-- One shop per account for now.
create unique index shops_one_per_owner on shops(owner_id);

create table shop_products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references shops(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  category product_category not null,
  price_omr numeric(10, 3) check (price_omr is null or price_omr >= 0),
  unit text check (unit is null or char_length(unit) <= 30),
  available boolean not null default true,
  updated_at timestamptz not null default now()
);
create index shop_products_shop on shop_products(shop_id);

-- Access: everyone sees approved shops and their products; an owner sees and
-- edits their own shop (any status) and its products; the admin does everything.
alter table public.shops enable row level security;
grant select on public.shops to anon, authenticated;
grant insert, update, delete on public.shops to authenticated;
create policy shops_read_approved on public.shops for select to anon, authenticated
  using (status = 'approved');
create policy shops_read_own on public.shops for select to authenticated
  using (owner_id = (select auth.uid()));
create policy shops_insert_own on public.shops for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'pending' and not is_demo);
create policy shops_update_own on public.shops for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy shops_delete_own on public.shops for delete to authenticated
  using (owner_id = (select auth.uid()));
create policy shops_admin_all on public.shops for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Owners may edit their details but never approve themselves or change owner.
create function public.guard_shop_privileged_columns() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated') and not public.is_admin()
     and (new.status is distinct from old.status
          or new.is_demo is distinct from old.is_demo
          or new.owner_id is distinct from old.owner_id) then
    raise exception 'only an admin can change status, demo flag or owner'
      using errcode = 'insufficient_privilege';
  end if;
  return new;
end;
$$;
create trigger shops_guard_privileged_columns
  before update on public.shops
  for each row execute function public.guard_shop_privileged_columns();

alter table public.shop_products enable row level security;
grant select on public.shop_products to anon, authenticated;
grant insert, update, delete on public.shop_products to authenticated;
create policy shop_products_read_approved on public.shop_products for select to anon, authenticated
  using (exists (select 1 from public.shops s where s.id = shop_id and s.status = 'approved'));
create policy shop_products_owner_all on public.shop_products for all to authenticated
  using (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())));
create policy shop_products_admin_all on public.shop_products for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create function public.touch_updated_at() returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
create trigger shop_products_touch
  before update on public.shop_products
  for each row execute function public.touch_updated_at();
