"""Omani Hijri month starts: readable by everyone, written by the admin only."""
import uuid

import psycopg
import pytest
from supabase.tests.conftest import as_role

USER, ADMIN = str(uuid.uuid4()), str(uuid.uuid4())
ROW = "insert into hijri_month_starts values (1448, 6, '2026-11-11', 'إعلان لجنة رؤية الهلال')"


def _users(db):
    for uid in (USER, ADMIN):
        db.execute("insert into auth.users(id) values (%s)", [uid])
    db.execute("update profiles set role = 'admin' where id = %s", [ADMIN])


def test_admin_writes_everyone_reads(db):
    _users(db)
    with as_role(db, "authenticated", ADMIN):
        db.execute(ROW)
    with as_role(db, "anon"):
        assert db.execute("select hijri_month, starts_on::text from hijri_month_starts").fetchall() == [
            (6, "2026-11-11")]


def test_non_admin_cannot_write(db):
    _users(db)
    with as_role(db, "authenticated", USER):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute(ROW)
    with as_role(db, "anon"):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute(ROW)


def test_checks(db):
    for bad in ("(1448, 13, '2026-11-11', 'source')", "(1448, 6, '2026-11-11', 'x')"):
        with pytest.raises(psycopg.errors.CheckViolation):
            with db.transaction():
                db.execute(f"insert into hijri_month_starts values {bad}")
    db.execute(ROW)
    with pytest.raises(psycopg.errors.UniqueViolation):
        db.execute("insert into hijri_month_starts values (1448, 7, '2026-11-11', 'other')")
