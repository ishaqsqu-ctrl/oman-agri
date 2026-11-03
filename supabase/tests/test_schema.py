import psycopg
import pytest


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
