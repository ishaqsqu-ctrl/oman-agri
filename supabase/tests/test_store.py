"""Store: shops register as pending, only the admin approves, everyone sees
approved shops and their products, owners manage only their own."""
import uuid

import psycopg
import pytest
from supabase.tests.conftest import as_role

OWNER, OTHER, ADMIN = (str(uuid.uuid4()) for _ in range(3))


def _setup(db):
    for uid in (OWNER, OTHER, ADMIN):
        db.execute("insert into auth.users(id) values (%s)", [uid])
    db.execute("update profiles set role = 'admin' where id = %s", [ADMIN])
    db.execute("insert into sources(id, title, publisher, type) values ('s1', 'T', 'P', 'other')")
    db.execute("insert into governorates(id, name_ar, name_en, source_id) values ('g', 'م', 'G', 's1')")
    db.execute("insert into wilayats(id, governorate_id, name_ar, name_en, source_id) "
               "values ('w', 'g', 'و', 'W', 's1')")


def _shop(db, owner=OWNER, **over):
    cols = {"owner_id": owner, "name": "محل الخير", "wilayat_id": "w", "phone": "+968 9123 4567", **over}
    return db.execute(
        f"insert into shops({', '.join(cols)}) values ({', '.join(['%s'] * len(cols))}) returning id",
        list(cols.values())).fetchone()[0]


def _product(db, shop_id, name="بذور طماطم"):
    db.execute("insert into shop_products(shop_id, name, category, price_omr) values (%s, %s, 'seeds', 1.5)",
               [shop_id, name])


def test_owner_registers_pending_and_cannot_self_approve(db):
    _setup(db)
    with as_role(db, "authenticated", OWNER):
        sid = _shop(db)
        assert db.execute("select status from shops where id = %s", [sid]).fetchone() == ("pending",)
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute("update shops set status = 'approved' where id = %s", [sid])


def test_cannot_register_as_approved_or_for_someone_else(db):
    _setup(db)
    with as_role(db, "authenticated", OWNER):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            _shop(db, status="approved")
    with as_role(db, "authenticated", OWNER):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            _shop(db, owner=OTHER)


def test_public_sees_only_approved_shops_and_their_products(db):
    _setup(db)
    pending = _shop(db, owner=OWNER)
    approved = _shop(db, owner=OTHER, status="approved")
    _product(db, pending)
    _product(db, approved, "سماد")
    with as_role(db, "anon"):
        assert db.execute("select id from shops").fetchall() == [(approved,)]
        assert db.execute("select name from shop_products").fetchall() == [("سماد",)]


def test_owner_sees_own_pending_shop_and_manages_its_products_only(db):
    _setup(db)
    mine = _shop(db, owner=OWNER)
    theirs = _shop(db, owner=OTHER, status="approved")
    with as_role(db, "authenticated", OWNER):
        assert {r[0] for r in db.execute("select id from shops").fetchall()} == {mine, theirs}
        _product(db, mine)
        db.execute("update shops set name = 'محل البركة', phone = '99112233' where id = %s", [mine])
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            _product(db, theirs)
    with as_role(db, "authenticated", OWNER):
        assert db.execute("update shop_products set price_omr = 2 where shop_id = %s returning 1",
                          [theirs]).fetchall() == []


def test_admin_approves_and_suspends(db):
    _setup(db)
    sid = _shop(db)
    with as_role(db, "authenticated", ADMIN):
        db.execute("update shops set status = 'approved' where id = %s", [sid])
    with as_role(db, "anon"):
        assert db.execute("select count(*) from shops").fetchone() == (1,)
    with as_role(db, "authenticated", ADMIN):
        db.execute("update shops set status = 'suspended' where id = %s", [sid])
    with as_role(db, "anon"):
        assert db.execute("select count(*) from shops").fetchone() == (0,)


def test_one_shop_per_account_and_field_checks(db):
    _setup(db)
    _shop(db)
    with pytest.raises(psycopg.errors.UniqueViolation):
        with db.transaction():
            _shop(db)
    for bad in ({"phone": "call me"}, {"name": "x"}, {"whatsapp": "abc"}):
        with pytest.raises(psycopg.errors.CheckViolation):
            with db.transaction():
                _shop(db, owner=OTHER, **bad)
    with pytest.raises(psycopg.errors.CheckViolation):
        with db.transaction():
            db.execute("insert into shop_products(shop_id, name, category, price_omr) "
                       "select id, 'x1', 'seeds', -1 from shops limit 1")
