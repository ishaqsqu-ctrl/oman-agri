import csv
import json
import shutil
import subprocess
import sys
from decimal import Decimal
from pathlib import Path

import pytest

from data.csvio import read_rows
from data.export_snapshot import build_snapshot
from data.import_db import import_dir

FIX = Path(__file__).parent / "fixtures"
ROOT = Path(__file__).resolve().parents[2]
TABLES = ["sources", "governorates", "wilayats", "crops", "crop_requirements", "crop_stages"]


def copy_valid(tmp_path):
    dst = tmp_path / "set"
    shutil.copytree(FIX / "valid", dst)
    return dst


def set_cell(d, filename, row, column, value):
    p = d / filename
    with p.open(newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    rows[row - 1][rows[0].index(column)] = value
    with p.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows(rows)


def counts(conn):
    return {t: conn.execute(f"select count(*) from {t}").fetchone()[0] for t in TABLES}


def expected_counts():
    return {t: len(read_rows(FIX / "valid" / f"{t}.csv")) for t in TABLES}


def test_import_counts_and_idempotent(db):
    exp = expected_counts()
    assert import_dir(FIX / "valid", db) == exp
    assert counts(db) == exp
    assert import_dir(FIX / "valid", db) == exp
    assert counts(db) == exp


def test_import_types(db):
    import_dir(FIX / "valid", db)
    t_min, textures = db.execute(
        "select t_min, textures::text[] from crop_requirements where crop_id='tomato'").fetchone()
    assert t_min == Decimal("10") and textures == ["sand", "loam"]
    cats = db.execute("select categories::text[] from crops where id='lime'").fetchone()[0]
    assert cats == ["fruit", "tree"]
    assert db.execute("select reviewed_at is not null from governorates where id='muscat'").fetchone()[0]


def test_import_excel_fixture_same_as_valid(db):
    import_dir(FIX / "excel", db)
    assert counts(db) == expected_counts()


def test_import_rejects_invalid(committed_db, tmp_path):
    d = copy_valid(tmp_path)
    set_cell(d, "crop_stages.csv", 2, "kc", "9.9")
    with pytest.raises(ValueError) as e:
        import_dir(d, committed_db)
    assert "kc" in str(e.value)
    committed_db.rollback()
    assert all(n == 0 for n in counts(committed_db).values())


def test_import_rolls_back_on_db_error(committed_db, tmp_path):
    import psycopg
    d = copy_valid(tmp_path)
    # Force a DB-level failure mid-import (last table missing): earlier tables must roll back.
    committed_db.execute("drop table crop_stages")
    committed_db.commit()
    with pytest.raises(psycopg.Error):
        import_dir(d, committed_db)
    committed_db.rollback()
    assert committed_db.execute("select count(*) from sources").fetchone()[0] == 0


def test_import_updates_changed_value(committed_db, tmp_path):
    d = copy_valid(tmp_path)
    import_dir(d, committed_db)
    committed_db.commit()
    set_cell(d, "crops.csv", 2, "name_en", "Tomato (garden)")
    import_dir(d, committed_db)
    committed_db.commit()
    assert committed_db.execute("select name_en from crops where id='tomato'").fetchone()[0] == "Tomato (garden)"
    assert counts(committed_db) == expected_counts()


def test_cli_import_commits(committed_db, pg_cluster):
    r = subprocess.run(
        [sys.executable, "-m", "data.import_db", str(FIX / "valid"), "--dsn",
         f"{committed_db.info.dsn}"], cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    committed_db.rollback()
    assert counts(committed_db) == expected_counts()


def test_snapshot_shape():
    s = build_snapshot(FIX / "valid", now="2026-11-03T00:00:00+00:00")
    assert s["schema_version"] == 1
    assert s["generated_at"] == "2026-11-03T00:00:00+00:00"
    assert len(s["sources"]) == 2 and len(s["governorates"]) == 2 and len(s["wilayats"]) == 2
    tomato = next(c for c in s["crops"] if c["id"] == "tomato")
    assert "crop_id" not in tomato["requirements"]
    assert tomato["requirements"]["t_min"] == 10 and tomato["requirements"]["textures"] == ["sand", "loam"]
    assert tomato["requirements"]["chill_hours_min"] is None
    assert tomato["requirements"]["status"] == "draft" and tomato["requirements"]["source_id"] == "fao56"
    seqs = [st["seq"] for st in tomato["stages"]]
    assert seqs == sorted(seqs) and len(seqs) >= 2
    assert all("crop_id" not in st for st in tomato["stages"])
    assert tomato["stages"][0]["kc"] == 0.6 and tomato["stages"][0]["status"] == "draft"
    assert tomato["categories"] == ["vegetable"]
    muscat = next(g for g in s["governorates"] if g["id"] == "muscat")
    assert muscat["reviewed_at"] == "2026-10-01" and muscat["status"] == "published"
    lime = next(c for c in s["crops"] if c["id"] == "lime")
    assert lime["requirements"] is None or isinstance(lime["requirements"], dict)


def test_snapshot_numbers_are_json_numbers():
    s = build_snapshot(FIX / "valid", now="x")
    text = json.dumps(s, default=str)
    back = json.loads(text)
    tomato = next(c for c in back["crops"] if c["id"] == "tomato")
    assert isinstance(tomato["requirements"]["t_min"], int)
    assert isinstance(tomato["stages"][0]["kc"], float)


def test_snapshot_rejects_invalid(tmp_path):
    d = copy_valid(tmp_path)
    set_cell(d, "crop_stages.csv", 2, "kc", "9.9")
    with pytest.raises(ValueError):
        build_snapshot(d)


def test_snapshot_cli_writes_unescaped_arabic(tmp_path):
    out = tmp_path / "out" / "knowledge.json"
    r = subprocess.run([sys.executable, "-m", "data.export_snapshot", str(FIX / "valid"),
                        "--out", str(out)], cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    text = out.read_text(encoding="utf-8")
    assert "طماطم" in text and "\\u0637" not in text
    assert json.loads(text)["schema_version"] == 1


# --- final review: CSV is the source of truth for status (ruling F1) ---
def _status(conn, table, where):
    return conn.execute(f"select status::text from {table} where {where}").fetchone()[0]


def test_import_keeps_published_when_csv_says_reviewed(committed_db, tmp_path):
    d = copy_valid(tmp_path)
    set_cell(d, "crops.csv", 2, "status", "reviewed")
    set_cell(d, "crops.csv", 2, "reviewed_by", "test-reviewer")
    set_cell(d, "crops.csv", 2, "reviewed_at", "2026-10-01")
    import_dir(d, committed_db)
    committed_db.commit()
    # Admin publishes in the DB (admin-panel shortcut), CSV still says reviewed.
    committed_db.execute("update crops set status='published' where id='tomato'")
    committed_db.commit()
    import_dir(d, committed_db)
    committed_db.commit()
    assert _status(committed_db, "crops", "id='tomato'") == "published"
    assert _status(committed_db, "crops", "id='lime'") == "draft"


def test_import_draft_in_csv_unpublishes(committed_db, tmp_path):
    d = copy_valid(tmp_path)
    import_dir(d, committed_db)
    committed_db.commit()
    assert _status(committed_db, "governorates", "id='muscat'") == "published"
    set_cell(d, "governorates.csv", 2, "status", "draft")
    import_dir(d, committed_db)
    committed_db.commit()
    assert _status(committed_db, "governorates", "id='muscat'") == "draft"


def test_import_csv_published_publishes(committed_db, tmp_path):
    d = copy_valid(tmp_path)
    import_dir(d, committed_db)
    committed_db.commit()
    set_cell(d, "crops.csv", 2, "status", "published")
    set_cell(d, "crops.csv", 2, "reviewed_by", "test-reviewer")
    set_cell(d, "crops.csv", 2, "reviewed_at", "2026-10-01")
    import_dir(d, committed_db)
    committed_db.commit()
    assert _status(committed_db, "crops", "id='tomato'") == "published"
