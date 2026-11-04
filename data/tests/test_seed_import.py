"""Task 10: the real seed set in data/ imports cleanly; review stamps are consistent."""
from pathlib import Path

from data.export_snapshot import build_snapshot
from data.import_db import import_dir
from data.validate import validate_dir

DATA = Path(__file__).resolve().parents[1]
CROP_IDS = {
    "tomato", "cucumber", "onion", "potato", "watermelon", "garlic", "cowpea", "wheat_omani",
    "alfalfa", "date_palm", "lime_omani", "banana", "pomegranate", "turmeric", "damask_rose",
    "okra", "eggplant", "pepper", "carrot", "muskmelon", "faba_bean", "fenugreek", "sorghum",
    "rhodes_grass", "mango", "coconut", "papaya", "grape", "walnut", "frankincense", "henna",
    "bougainvillea",
}


def test_seed_validates():
    assert validate_dir(DATA) == []


def test_seed_import_crops_and_requirements(db):
    counts = import_dir(DATA, db)
    assert counts["crops"] == 32
    assert {r[0] for r in db.execute("select id from crops")} == CROP_IDS
    missing = db.execute(
        "select id from crops c where not exists "
        "(select 1 from crop_requirements r where r.crop_id = c.id)").fetchall()
    assert missing == []


def test_seed_import_admin_divisions(db):
    counts = import_dir(DATA, db)
    assert counts["governorates"] == 11
    assert counts["wilayats"] == 63
    orphans = db.execute(
        "select id from wilayats w where not exists "
        "(select 1 from governorates g where g.id = w.governorate_id)").fetchall()
    assert orphans == []


def test_seed_review_stamps_and_known_sources():
    s = build_snapshot(DATA, now="x")
    source_ids = {src["id"] for src in s["sources"]}
    assert {"fao56", "fao29", "ecocrop", "ncsi_admin"} <= source_ids
    rows = s["governorates"] + s["wilayats"] + s["crops"]
    rows += [c["requirements"] for c in s["crops"] if c["requirements"]]
    rows += [st for c in s["crops"] for st in c["stages"]]
    assert rows
    for r in rows:
        assert r["source_id"] in source_ids
        assert r["source_page"]
        if r["status"] == "draft":
            assert r["reviewed_by"] is None and r["reviewed_at"] is None
        else:
            assert r["status"] in ("reviewed", "published")
            assert r["reviewed_by"] and r["reviewed_at"]
