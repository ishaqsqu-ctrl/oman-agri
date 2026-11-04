import psycopg
import pytest
from supabase.tests.conftest import as_role


def _source(db):
    db.execute(
        "insert into sources(id, title, publisher, type) "
        "values ('s1', 'T', 'P', 'ministry')"
    )


def _crop(db, crop_id="tomato", **over):
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


def test_published_requires_review(db):
    _source(db)
    with pytest.raises(psycopg.errors.CheckViolation):
        _crop(db, status="published")


def test_source_required(db):
    _source(db)
    with pytest.raises(psycopg.errors.NotNullViolation):
        _crop(db, source_id=None)


def test_temperature_order(db):
    _source(db)
    _crop(db)
    with pytest.raises(psycopg.errors.CheckViolation):
        db.execute(
            "insert into crop_requirements"
            "(crop_id, t_min, t_opt_low, t_opt_high, t_max, source_id) "
            "values ('tomato', 5, 30, 20, 40, 's1')"
        )


def test_kc_bounds(db):
    _source(db)
    _crop(db)
    with pytest.raises(psycopg.errors.CheckViolation):
        db.execute(
            "insert into crop_stages"
            "(crop_id, seq, stage, duration_days, kc, source_id) "
            "values ('tomato', 1, 'initial', 10, 1.6, 's1')"
        )


def test_profile_created_on_signup(db):
    uid = "11111111-1111-1111-1111-111111111111"
    db.execute("insert into auth.users(id, email) values (%s, 'a@b.om')", [uid])
    row = db.execute("select role from public.profiles where id = %s", [uid]).fetchone()
    assert row == ("farmer",)


UID = "22222222-2222-2222-2222-222222222222"


def test_as_role_sets_uid_and_role(db):
    with as_role(db, "authenticated", UID):
        assert db.execute("select current_user, auth.uid()::text").fetchone() == (
            "authenticated",
            UID,
        )
    assert db.execute("select current_user, auth.uid()").fetchone() == ("postgres", None)


def test_as_role_restores_after_failed_statement(db):
    _source(db)
    with as_role(db, "authenticated", UID):
        with pytest.raises(psycopg.errors.InsufficientPrivilege):
            db.execute(
                "insert into sources(id, title, publisher, type) "
                "values ('bad', 'T', 'P', 'other')"
            )
    assert db.execute("select current_user, auth.uid()").fetchone() == ("postgres", None)
    assert db.execute("select count(*) from sources").fetchone() == (1,)


def test_committed_db_is_isolated_and_commits(committed_db):
    committed_db.execute(
        "insert into sources(id, title, publisher, type) values ('c', 'T', 'P', 'other')"
    )
    committed_db.commit()
    assert committed_db.execute("select count(*) from sources").fetchone() == (1,)


def test_committed_db_fresh_per_test(committed_db):
    assert committed_db.execute("select count(*) from sources").fetchone() == (0,)


def test_kc_monthly_bounds(db):
    _source(db)
    _crop(db)
    for month, kc in ((13, 0.8), (0, 0.8), (6, 1.6)):
        with pytest.raises(psycopg.errors.CheckViolation):
            with db.transaction():
                db.execute(
                    "insert into crop_kc_monthly(crop_id, month, kc, source_id) "
                    "values ('tomato', %s, %s, 's1')", [month, kc])


def test_kc_monthly_one_row_per_month(db):
    _source(db)
    _crop(db)
    db.execute("insert into crop_kc_monthly(crop_id, month, kc, source_id) values ('tomato', 1, 0.7, 's1')")
    with pytest.raises(psycopg.errors.UniqueViolation):
        db.execute("insert into crop_kc_monthly(crop_id, month, kc, source_id) values ('tomato', 1, 0.8, 's1')")
