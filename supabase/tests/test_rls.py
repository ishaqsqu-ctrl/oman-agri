import uuid

import psycopg
import pytest
from conftest import as_role

FARMER = str(uuid.uuid4())
ADMIN = str(uuid.uuid4())
REVIEWER = {"reviewed_by": "dr-x", "reviewed_at": "2026-11-01T00:00:00Z"}


def _seed_users(db):
    for uid in (FARMER, ADMIN):
        db.execute("insert into auth.users(id) values (%s)", [uid])
    db.execute("update profiles set role = 'admin' where id = %s", [ADMIN])


def _source(db):
    db.execute(
        "insert into sources(id, title, publisher, type) values ('s1', 'T', 'P', 'ministry')"
    )


def _crop(db, crop_id, **over):
    cols = {
        "id": crop_id,
        "name_ar": "طماطم",
        "name_en": "Tomato",
        "categories": ["vegetable"],
        "source_id": "s1",
    }
    cols.update(over)
    names = ", ".join(cols)
    marks = ", ".join(["%s"] * len(cols))
    db.execute(f"insert into crops({names}) values ({marks})", list(cols.values()))


def _statuses(db):
    return dict(db.execute("select id, status from crops").fetchall())


def test_anon_sees_only_published(db):
    _source(db)
    _crop(db, "draft1")
    _crop(db, "pub1", status="published", **REVIEWER)
    with as_role(db, "anon"):
        rows = db.execute("select id from crops").fetchall()
        assert rows == [("pub1",)]
        assert db.execute("select count(*) from sources").fetchone() == (1,)


def test_farmer_cannot_write_knowledge(db):
    _seed_users(db)
    _source(db)
    with as_role(db, "authenticated", FARMER):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            _crop(db, "x")


def test_admin_can_write_and_read_drafts(db):
    _seed_users(db)
    _source(db)
    with as_role(db, "authenticated", ADMIN):
        _crop(db, "x")
        assert db.execute("select id from crops").fetchall() == [("x",)]


def test_farmer_cannot_promote_self(db):
    _seed_users(db)
    with as_role(db, "authenticated", FARMER):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute("update profiles set role = 'admin' where id = %s", [FARMER])
    assert db.execute(
        "select role from profiles where id = %s", [FARMER]
    ).fetchone() == ("farmer",)


def test_farmer_can_update_own_display_name_only_own_row(db):
    _seed_users(db)
    with as_role(db, "authenticated", FARMER):
        db.execute("update profiles set display_name = 'F' where id = %s", [FARMER])
        n = db.execute("update profiles set display_name = 'hax' where id = %s", [ADMIN]).rowcount
        assert n == 0
        assert db.execute("select count(*) from profiles").fetchone() == (1,)
    assert db.execute(
        "select display_name from profiles where id = %s", [FARMER]
    ).fetchone() == ("F",)


def test_publish_reviewed_admin(db):
    _seed_users(db)
    _source(db)
    _crop(db, "r1", status="reviewed", **REVIEWER)
    _crop(db, "r2", status="reviewed", **REVIEWER)
    _crop(db, "d1")
    with as_role(db, "authenticated", ADMIN):
        assert db.execute("select public.publish_reviewed('crops')").fetchone() == (2,)
    assert _statuses(db) == {"r1": "published", "r2": "published", "d1": "draft"}


def test_publish_reviewed_non_admin(db):
    _seed_users(db)
    with as_role(db, "authenticated", FARMER):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute("select public.publish_reviewed('crops')")


def test_publish_reviewed_anon_denied(db):
    with as_role(db, "anon"):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute("select public.publish_reviewed('crops')")


def test_publish_reviewed_bad_table(db):
    _seed_users(db)
    with as_role(db, "authenticated", ADMIN):
        with pytest.raises(psycopg.errors.InvalidParameterValue):
            db.execute("select public.publish_reviewed('profiles')")


def test_knowledge_status_counts(db):
    _seed_users(db)
    _source(db)
    _crop(db, "d1")
    _crop(db, "r1", status="reviewed", **REVIEWER)
    with as_role(db, "authenticated", ADMIN):
        rows = db.execute(
            "select status, n from public.knowledge_status_counts() "
            "where table_name = 'crops' and n > 0"
        ).fetchall()
    assert sorted(rows) == [("draft", 1), ("reviewed", 1)]


def test_knowledge_status_counts_non_admin(db):
    _seed_users(db)
    with as_role(db, "authenticated", FARMER):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute("select * from public.knowledge_status_counts()")
