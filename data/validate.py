"""Bilingual validator for the CSV knowledge files. Usage: python -m data.validate data/"""
import math
import re
import sys
from datetime import date, datetime
from pathlib import Path
from typing import NamedTuple

from .csvio import read_table
from .schema import COLUMNS, ENUMS, FILES

ARABIC_LETTER = re.compile(r"[ؠ-يٮ-ۓ]")
ARABIC_ANY = re.compile(r"[؀-ۿ]")


class Issue(NamedTuple):
    file: str
    row: int
    column: str
    message_ar: str
    message_en: str


def _num(v: str):
    try:
        x = float(v)
    except ValueError:
        return None
    return x if math.isfinite(x) else None


def _int(v: str):
    try:
        return int(v)
    except ValueError:
        x = _num(v)
        return int(x) if x is not None and x == int(x) and re.fullmatch(r"-?\d+\.0*", v) else None


def _valid_date(v: str) -> bool:
    try:
        date.fromisoformat(v)
        return True
    except ValueError:
        pass
    try:
        datetime.fromisoformat(v)
        return True
    except ValueError:
        return False


def validate_dir(path: Path) -> list[Issue]:
    path = Path(path)
    issues: list[Issue] = []
    tables: dict[str, list[tuple[int, dict[str, str]]]] = {}
    parsed: dict[tuple[str, int, str], object] = {}  # numeric values keyed by cell

    def add(f, r, c, ar, en):
        issues.append(Issue(f, r, c, ar, en))

    for fname in FILES:
        p = path / fname
        if not p.is_file():
            add(fname, 0, "", f"الملف مفقود: {fname}", f"Missing file: {fname}")
            tables[fname] = []
            continue
        header, rows = read_table(p)
        spec = COLUMNS[fname]
        names = [c for c, _, _ in spec]
        bad_header = False
        for c in names:
            if c not in header:
                bad_header = True
                add(fname, 1, c, f"العمود مفقود: {c}", f"Missing column: {c}")
        for c in header:
            if c not in names:
                bad_header = True
                add(fname, 1, c, f"عمود غير معروف: {c}", f"Unknown column: {c}")
        if bad_header:
            tables[fname] = []
            continue
        tables[fname] = rows
        for n, row in rows:
            for col, kind, required in spec:
                v = row[col]
                if v == "":
                    if required:
                        add(fname, n, col, f"قيمة مطلوبة: {col}", f"Required value: {col}")
                    continue
                if kind == "int":
                    x = _int(v)
                    if x is None:
                        add(fname, n, col, f"يجب أن يكون عددًا صحيحًا: {v}", f"Not a whole number: {v}")
                    else:
                        parsed[(fname, n, col)] = x
                elif kind == "num":
                    x = _num(v)
                    if x is None:
                        add(fname, n, col, f"يجب أن يكون رقمًا: {v}", f"Not a number: {v}")
                    else:
                        parsed[(fname, n, col)] = x
                elif kind.startswith("enum:"):
                    allowed = ENUMS[kind[5:]]
                    if v not in allowed:
                        add(fname, n, col, f"قيمة غير مسموحة «{v}»، المسموح: {', '.join(allowed)}",
                            f"Invalid value '{v}'; allowed: {', '.join(allowed)}")
                elif kind.startswith("enums:"):
                    allowed = ENUMS[kind[6:]]
                    for part in (s.strip() for s in v.split("|")):
                        if part not in allowed:
                            add(fname, n, col, f"قيمة غير مسموحة «{part}»، المسموح: {', '.join(allowed)}",
                                f"Invalid value '{part}'; allowed: {', '.join(allowed)}")
                            break

    def val(f, n, c):
        return parsed.get((f, n, c))

    def ids(f):
        return {r["id"] for _, r in tables[f] if r["id"]}

    # unique ids
    for f in ("sources.csv", "governorates.csv", "wilayats.csv", "crops.csv"):
        seen = set()
        for n, r in tables[f]:
            if r["id"] and r["id"] in seen:
                add(f, n, "id", f"المعرّف مكرر: {r['id']}", f"Duplicate id: {r['id']}")
            seen.add(r["id"])
    seen = set()
    for n, r in tables["crop_requirements.csv"]:
        if r["crop_id"] in seen:
            add("crop_requirements.csv", n, "crop_id", f"المحصول مكرر: {r['crop_id']}", f"Duplicate crop: {r['crop_id']}")
        seen.add(r["crop_id"])
    seen = set()
    for n, r in tables["crop_stages.csv"]:
        k = (r["crop_id"], r["seq"])
        if r["crop_id"] and r["seq"] and k in seen:
            add("crop_stages.csv", n, "seq", f"المرحلة مكررة: {r['crop_id']} #{r['seq']}", f"Duplicate stage: {r['crop_id']} #{r['seq']}")
        seen.add(k)

    # foreign keys
    src, gov, crops = ids("sources.csv"), ids("governorates.csv"), ids("crops.csv")
    for f in FILES[1:]:
        for n, r in tables[f]:
            if r["source_id"] and r["source_id"] not in src:
                add(f, n, "source_id", f"المصدر غير موجود: {r['source_id']}", f"Unknown source: {r['source_id']}")
    for n, r in tables["wilayats.csv"]:
        if r["governorate_id"] and r["governorate_id"] not in gov:
            add("wilayats.csv", n, "governorate_id", f"المحافظة غير موجودة: {r['governorate_id']}", f"Unknown governorate: {r['governorate_id']}")
    for f in ("crop_requirements.csv", "crop_stages.csv"):
        for n, r in tables[f]:
            if r["crop_id"] and r["crop_id"] not in crops:
                add(f, n, "crop_id", f"المحصول غير موجود: {r['crop_id']}", f"Unknown crop: {r['crop_id']}")

    # names
    for f in ("governorates.csv", "wilayats.csv", "crops.csv"):
        for n, r in tables[f]:
            if r["name_ar"] and not ARABIC_LETTER.search(r["name_ar"]):
                add(f, n, "name_ar", f"الاسم العربي يجب أن يحتوي حروفًا عربية: {r['name_ar']}", f"name_ar must contain Arabic letters: {r['name_ar']}")
            if r["name_en"] and ARABIC_ANY.search(r["name_en"]):
                add(f, n, "name_en", f"الاسم الإنجليزي يجب ألا يحتوي حروفًا عربية: {r['name_en']}", f"name_en must not contain Arabic letters: {r['name_en']}")

    # review metadata
    for f in FILES[1:]:
        for n, r in tables[f]:
            at = r["reviewed_at"]
            if at and not _valid_date(at):
                add(f, n, "reviewed_at", f"تاريخ غير صالح «{at}»، الصيغة YYYY-MM-DD", f"Invalid date '{at}'; use YYYY-MM-DD")
            if r["status"] in ("reviewed", "published"):
                if not r["reviewed_by"]:
                    add(f, n, "reviewed_by", f"الحالة {r['status']} تتطلب اسم المراجع", f"Status {r['status']} requires reviewed_by")
                if not at:
                    add(f, n, "reviewed_at", f"الحالة {r['status']} تتطلب تاريخ المراجعة", f"Status {r['status']} requires reviewed_at")

    # sources
    for n, r in tables["sources.csv"]:
        x = val("sources.csv", n, "reliability")
        if x is not None and not 1 <= x <= 3:
            add("sources.csv", n, "reliability", f"الموثوقية يجب أن تكون بين 1 و3: {x}", f"reliability must be 1..3: {x}")

    # requirements
    f = "crop_requirements.csv"
    for n, r in tables[f]:
        temps = [(c, val(f, n, c)) for c in ("t_min", "t_opt_low", "t_opt_high", "t_max") if val(f, n, c) is not None]
        for (c1, a), (c2, b) in zip(temps, temps[1:]):
            if a > b:
                add(f, n, c1, f"ترتيب الحرارة خاطئ: {c1} ({a:g}) أكبر من {c2} ({b:g})", f"Temperature order: {c1} ({a:g}) is greater than {c2} ({b:g})")
        for c in ("ph_min", "ph_max"):
            x = val(f, n, c)
            if x is not None and not 0 <= x <= 14:
                add(f, n, c, f"الرقم الهيدروجيني يجب أن يكون بين 0 و14: {x:g}", f"pH must be within 0..14: {x:g}")
        for lo, hi in (("ph_min", "ph_max"), ("alt_min", "alt_max"), ("season_days_min", "season_days_max")):
            a, b = val(f, n, lo), val(f, n, hi)
            if a is not None and b is not None and a > b:
                add(f, n, lo, f"{lo} ({a:g}) أكبر من {hi} ({b:g})", f"{lo} ({a:g}) is greater than {hi} ({b:g})")

    # stages
    f = "crop_stages.csv"
    by_crop: dict[str, list[tuple[int, int]]] = {}
    for n, r in tables[f]:
        d = val(f, n, "duration_days")
        if d is not None and d <= 0:
            add(f, n, "duration_days", f"المدة يجب أن تكون أكبر من صفر: {d}", f"duration_days must be > 0: {d}")
        k = val(f, n, "kc")
        if k is not None and not 0 <= k <= 1.5:
            add(f, n, "kc", f"قيمة kc يجب أن تكون بين 0 و1.5: {k:g}", f"kc must be within 0..1.5: {k:g}")
        s = val(f, n, "seq")
        if s is not None and r["crop_id"] in crops:
            by_crop.setdefault(r["crop_id"], []).append((s, n))
    for crop, items in by_crop.items():
        for i, (s, n) in enumerate(sorted(items), start=1):
            if s != i:
                add(f, n, "seq", f"تسلسل المراحل للمحصول {crop} يجب أن يكون متصلاً من 1 (المتوقع {i}، الموجود {s})",
                    f"Stage seq for {crop} must be contiguous from 1 (expected {i}, found {s})")
                break
    return issues


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else Path("data")
    issues = validate_dir(path)
    if issues:
        for i in issues:
            where = f"{i.file}:{i.row}:{i.column}"
            print(f"{where}\n  {i.message_ar}\n  {i.message_en}")
        return 1
    total = sum(len(read_table(path / f)[1]) for f in ("sources.csv", "governorates.csv", "wilayats.csv", "crops.csv", "crop_requirements.csv", "crop_stages.csv"))
    print(f"OK: {total} rows")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv))
