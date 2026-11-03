import csv
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

from data.csvio import read_rows
from data.validate import validate_dir

FIX = Path(__file__).parent / "fixtures"
ROOT = Path(__file__).resolve().parents[2]


def broken(tmp_path, filename, row, column, value):
    """Copy the valid set and overwrite one cell (row is the 1-based sheet row)."""
    dst = tmp_path / "set"
    shutil.copytree(FIX / "valid", dst)
    p = dst / filename
    with p.open(newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    rows[row - 1][rows[0].index(column)] = value
    with p.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows(rows)
    return dst


def one_issue(d, file, row, column):
    issues = validate_dir(d)
    assert len(issues) == 1, issues
    i = issues[0]
    assert (i.file, i.row, i.column) == (file, row, column)
    assert i.message_ar and i.message_en
    return i


def test_valid_fixture_ok():
    assert validate_dir(FIX / "valid") == []


def test_excel_artifacts_ok():
    assert validate_dir(FIX / "excel") == []
    assert read_rows(FIX / "excel" / "crops.csv") == read_rows(FIX / "valid" / "crops.csv")


def test_ignores_non_knowledge_files(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    (d / "README.md").write_text("hi")
    (d / "notes.csv").write_text("garbage")
    assert validate_dir(d) == []


def test_missing_file(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    (d / "wilayats.csv").unlink()
    i = one_issue(d, "wilayats.csv", 0, "")
    assert "wilayats.csv" in i.message_en


def test_missing_column(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    p = d / "sources.csv"
    p.write_text(p.read_text(encoding="utf-8").replace(",reliability", ""), encoding="utf-8")
    issues = validate_dir(d)
    assert any(i.file == "sources.csv" and i.column == "reliability" for i in issues)


CASES = [
    # id, file, row, column, value
    ("dup_id", "crops.csv", 3, "id", "tomato"),
    ("unknown_source", "crops.csv", 2, "source_id", "fao99"),
    ("unknown_governorate", "wilayats.csv", 2, "governorate_id", "nowhere"),
    ("unknown_crop_req", "crop_requirements.csv", 2, "crop_id", "ghost"),
    ("unknown_crop_stage", "crop_stages.csv", 4, "crop_id", "ghost"),
    ("dup_requirements_crop", None, None, None, None),
    ("bad_status", "crops.csv", 2, "status", "final"),
    ("bad_source_type", "sources.csv", 2, "type", "blog"),
    ("bad_category", "crops.csv", 2, "categories", "vegetable|rock"),
    ("empty_category", "crops.csv", 2, "categories", ""),
    ("bad_lifecycle", "crops.csv", 2, "lifecycle", "biennial"),
    ("bad_texture", "crop_requirements.csv", 2, "textures", "sand|gravel"),
    ("bad_stage", "crop_stages.csv", 2, "stage", "flowering"),
    ("non_numeric", "crop_requirements.csv", 2, "t_max", "hot"),
    ("non_integer", "crop_requirements.csv", 2, "alt_max", "1500.5"),
    ("reliability_range", "sources.csv", 2, "reliability", "4"),
    ("temp_order", "crop_requirements.csv", 2, "t_opt_low", "30"),
    ("kc_high", "crop_stages.csv", 3, "kc", "1.6"),
    ("kc_negative", "crop_stages.csv", 3, "kc", "-0.1"),
    ("kc_missing", "crop_stages.csv", 3, "kc", ""),
    ("duration_zero", "crop_stages.csv", 3, "duration_days", "0"),
    ("ph_range", "crop_requirements.csv", 2, "ph_max", "15"),
    ("ph_order", "crop_requirements.csv", 2, "ph_min", "8"),
    ("alt_order", "crop_requirements.csv", 2, "alt_min", "2000"),
    ("season_order", "crop_requirements.csv", 2, "season_days_min", "200"),
    ("published_no_reviewer", "governorates.csv", 2, "reviewed_by", ""),
    ("published_no_date", "governorates.csv", 2, "reviewed_at", ""),
    ("bad_date", "governorates.csv", 2, "reviewed_at", "01/10/2026"),
    ("name_ar_not_arabic", "crops.csv", 2, "name_ar", "Tomato"),
    ("name_ar_empty", "crops.csv", 2, "name_ar", ""),
    ("name_en_arabic", "crops.csv", 2, "name_en", "طماطم"),
    ("name_en_empty", "crops.csv", 2, "name_en", ""),
    ("source_missing", "crops.csv", 2, "source_id", ""),
    ("stage_seq_gap", "crop_stages.csv", 4, "seq", "5"),
    ("stage_seq_not_from_1", None, None, None, None),
    ("seq_not_int", "crop_stages.csv", 4, "seq", "x"),
]


@pytest.mark.parametrize("name,file,row,column,value", [c for c in CASES if c[1]], ids=[c[0] for c in CASES if c[1]])
def test_single_defect(tmp_path, name, file, row, column, value):
    d = broken(tmp_path, file, row, column, value)
    i = one_issue(d, file, row, column)
    if name == "unknown_source":
        assert i.message_en == "Unknown source: fao99"
        assert i.message_ar == "المصدر غير موجود: fao99"


def test_dup_requirements_crop(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    p = d / "crop_requirements.csv"
    lines = p.read_text(encoding="utf-8").splitlines()
    p.write_text("\n".join(lines + [lines[1]]) + "\n", encoding="utf-8")
    one_issue(d, "crop_requirements.csv", 3, "crop_id")


def test_stage_seq_must_start_at_1(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    p = d / "crop_stages.csv"
    lines = p.read_text(encoding="utf-8").splitlines()
    p.write_text("\n".join(lines[:1] + lines[2:]) + "\n", encoding="utf-8")  # seq 2,3
    one_issue(d, "crop_stages.csv", 2, "seq")


def test_datetime_reviewed_at_accepted(tmp_path):
    d = broken(tmp_path, "governorates.csv", 2, "reviewed_at", "2026-10-01T08:30:00+04:00")
    assert validate_dir(d) == []


def test_reviewed_status_requires_review_fields(tmp_path):
    d = broken(tmp_path, "governorates.csv", 3, "status", "reviewed")
    issues = validate_dir(d)
    assert {(i.row, i.column) for i in issues} == {(3, "reviewed_by"), (3, "reviewed_at")}


def run_cli(path):
    return subprocess.run([sys.executable, "-m", "data.validate", str(path)],
                          cwd=ROOT, capture_output=True, text=True)


def test_cli_exit_codes(tmp_path):
    ok = run_cli(FIX / "valid")
    assert ok.returncode == 0 and ok.stdout.startswith("OK:")
    d = broken(tmp_path, "crops.csv", 2, "source_id", "fao99")
    bad = run_cli(d)
    assert bad.returncode == 1
    assert "المصدر غير موجود: fao99" in bad.stdout and "Unknown source: fao99" in bad.stdout


# --- fix round 1 ---
from decimal import Decimal  # noqa: E402

from data.values import parse_int, parse_num  # noqa: E402


def test_parsers_accept_arabic_digits():
    assert parse_int("١٢") == 12
    assert parse_int("۱۲") == 12
    assert parse_int("-5") == -5
    assert parse_num("٣٫٥") == Decimal("3.5")
    assert parse_num(".5") == Decimal("0.5")
    assert parse_num("7") == Decimal("7")


@pytest.mark.parametrize("s", ["1_000", "+5", "1.", "1.0", "1e3", "", "-", "1,5", "NaN"])
def test_parse_int_rejects(s):
    with pytest.raises(ValueError):
        parse_int(s)


@pytest.mark.parametrize("s", ["1_000", "+5", "1.", "1e3", "", ".", "inf", "1,5"])
def test_parse_num_rejects(s):
    with pytest.raises(ValueError):
        parse_num(s)


def test_arabic_digits_in_csv_ok(tmp_path):
    assert validate_dir(broken(tmp_path, "crop_requirements.csv", 2, "ph_max", "٧٫٥")) == []


def test_float_formatted_int_rejected(tmp_path):
    one_issue(broken(tmp_path, "crop_requirements.csv", 2, "alt_max", "1500.0"), "crop_requirements.csv", 2, "alt_max")


@pytest.mark.parametrize("file,row,col,val", [
    ("crop_requirements.csv", 2, "alt_max", "99999999999"),
    ("crop_stages.csv", 4, "seq", "40000"),
    ("crop_stages.csv", 3, "duration_days", "2147483648"),
])
def test_int_width(tmp_path, file, row, col, val):
    one_issue(broken(tmp_path, file, row, col, val), file, row, col)


def test_non_utf8_file(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    (d / "crops.csv").write_bytes(
        "id,name_ar\nx,طماطم\n".encode("cp1256"))
    i = one_issue(d, "crops.csv", 0, "")
    assert i.message_en == "File must be saved as CSV UTF-8"
    assert i.message_ar == "يجب حفظ الملف بصيغة CSV UTF-8"
    r = run_cli(d)
    assert r.returncode == 1 and "Traceback" not in r.stderr
    assert "File must be saved as CSV UTF-8" in r.stdout


def test_invisible_chars_stripped(tmp_path):
    d = broken(tmp_path, "crops.csv", 2, "name_en", "‎Tomato ​")
    assert validate_dir(d) == []
    assert read_rows(d / "crops.csv")[0]["name_en"] == "Tomato"


def test_duplicate_header(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    p = d / "governorates.csv"
    p.write_text(p.read_text(encoding="utf-8").replace("name_en", "name_ar", 1), encoding="utf-8")
    assert any(i.column == "name_ar" and i.row == 1 and "Duplicate" in i.message_en for i in validate_dir(d))


def test_extra_cells(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    p = d / "governorates.csv"
    lines = p.read_text(encoding="utf-8").splitlines()
    lines[2] += ",oops"
    p.write_text("\n".join(lines) + "\n", encoding="utf-8")
    one_issue(d, "governorates.csv", 3, "")


def test_empty_id_no_duplicate_noise(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    p = d / "governorates.csv"
    lines = p.read_text(encoding="utf-8").splitlines()
    blank = ",x,y,draft,moa1,,,"
    p.write_text("\n".join(lines + [blank.replace("x", "غ").replace("y", "Y"), blank.replace("x", "ف").replace("y", "Z")]) + "\n", encoding="utf-8")
    issues = validate_dir(d)
    assert all("Duplicate" not in i.message_en for i in issues) and len(issues) == 2


# --- final review: Excel trailing columns, unnamed columns, semicolons ---
def _rewrite_lines(d, filename, fn):
    p = d / filename
    lines = p.read_text(encoding="utf-8").splitlines()
    p.write_text("\n".join(fn(lines)) + "\n", encoding="utf-8")


def test_trailing_empty_columns_ignored(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    for f in d.glob("*.csv"):
        _rewrite_lines(d, f.name, lambda ls: [l + ",," for l in ls])
    assert validate_dir(d) == []
    assert read_rows(d / "crops.csv") == read_rows(FIX / "valid" / "crops.csv")


def test_trailing_unnamed_column_with_data(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    _rewrite_lines(d, "governorates.csv", lambda ls: [ls[0] + ",", ls[1] + ",note", *ls[2:]])
    i = one_issue(d, "governorates.csv", 1, "")
    assert i.message_en == "Unnamed column at position 9"
    assert i.message_ar == "عمود بلا اسم في الموضع 9"


def test_unnamed_column_in_middle(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    _rewrite_lines(d, "governorates.csv",
                   lambda ls: [l.replace(",", ",,", 1) for l in ls])
    i = one_issue(d, "governorates.csv", 1, "")
    assert i.message_en == "Unnamed column at position 2"
    assert i.message_ar == "عمود بلا اسم في الموضع 2"


def test_semicolon_delimited_file(tmp_path):
    d = tmp_path / "set"
    shutil.copytree(FIX / "valid", d)
    _rewrite_lines(d, "governorates.csv", lambda ls: [l.replace(",", ";") for l in ls])
    i = one_issue(d, "governorates.csv", 1, "")
    assert i.message_en == "File appears to use semicolons; save as CSV UTF-8 (comma-delimited)"
    assert i.message_ar == "يبدو أن الملف محفوظ بفاصلة منقوطة؛ احفظه بصيغة CSV UTF-8 (فاصلة)"


@pytest.mark.parametrize("url", ["javascript:alert(1)", "www.example.invalid", "ftp://example.invalid/x"])
def test_source_url_must_be_http(tmp_path, url):
    i = one_issue(broken(tmp_path, "sources.csv", 2, "url", url), "sources.csv", 2, "url")
    assert "http" in i.message_en and "http" in i.message_ar


@pytest.mark.parametrize("url", ["", "http://example.invalid", "HTTPS://example.invalid/a"])
def test_source_url_http_ok(tmp_path, url):
    assert validate_dir(broken(tmp_path, "sources.csv", 2, "url", url)) == []
