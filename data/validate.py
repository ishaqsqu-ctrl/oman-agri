"""Bilingual validator for the CSV knowledge files. Usage: python -m data.validate data/"""
import re
import sys
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import NamedTuple

from .csvio import read_table
from .values import parse_int, parse_num
from .schema import COLUMNS, ENUMS, FILES

ARABIC_LETTER = re.compile(r"[ؠ-يٮ-ۓ]")
INT_RANGES = {"int": (-2147483648, 2147483647), "smallint": (-32768, 32767)}
ARABIC_ANY = re.compile(r"[؀-ۿ]")


class Issue(NamedTuple):
    file: str
    row: int
    column: str
    message_ar: str
    message_en: str


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
    unusable: set[str] = set()  # files that could not be read: skip FK checks against them
    parsed: dict[tuple[str, int, str], object] = {}  # numeric values keyed by cell

    def add(f, r, c, ar, en):
        issues.append(Issue(f, r, c, ar, en))

    for fname in FILES:
        p = path / fname
        if not p.is_file():
            add(fname, 0, "", f"الملف مفقود: {fname}", f"Missing file: {fname}")
            tables[fname] = []
            unusable.add(fname)
            continue
        try:
            header, rows, problems = read_table(p)
        except UnicodeDecodeError:
            add(fname, 0, "", "يجب حفظ الملف بصيغة CSV UTF-8", "File must be saved as CSV UTF-8")
            tables[fname] = []
            unusable.add(fname)
            continue
        spec = COLUMNS[fname]
        names = [c for c, _, _ in spec]
        if any(kind == "semicolon" for _, _, kind in problems):
            add(fname, 1, "", "يبدو أن الملف محفوظ بفاصلة منقوطة؛ احفظه بصيغة CSV UTF-8 (فاصلة)",
                "File appears to use semicolons; save as CSV UTF-8 (comma-delimited)")
            tables[fname] = []
            unusable.add(fname)
            continue
        bad_header = False
        for r_, c_, kind in problems:
            bad_header = bad_header or kind in ("duplicate_header", "unnamed_header")
            if kind == "duplicate_header":
                add(fname, r_, c_, f"اسم العمود مكرر: {c_}", f"Duplicate column: {c_}")
            elif kind == "unnamed_header":
                add(fname, r_, "", f"عمود بلا اسم في الموضع {c_}", f"Unnamed column at position {c_}")
            else:
                add(fname, r_, c_, "عدد الخلايا في الصف أكبر من عدد الأعمدة", "Row has more cells than header columns")
        for c in names:
            if c not in header:
                bad_header = True
                add(fname, 1, c, f"العمود مفقود: {c}", f"Missing column: {c}")
        for c in header:
            if c and c not in names:
                bad_header = True
                add(fname, 1, c, f"عمود غير معروف: {c}", f"Unknown column: {c}")
        if bad_header:
            tables[fname] = []
            unusable.add(fname)
            continue
        tables[fname] = rows
        for n, row in rows:
            for col, kind, required in spec:
                v = row[col]
                if v == "":
                    if required:
                        add(fname, n, col, f"قيمة مطلوبة: {col}", f"Required value: {col}")
                    continue
                if kind in INT_RANGES:
                    lo_, hi_ = INT_RANGES[kind]
                    try:
                        x = parse_int(v)
                    except ValueError:
                        add(fname, n, col, f"يجب أن يكون عددًا صحيحًا: {v}", f"Not a whole number: {v}")
                    else:
                        if lo_ <= x <= hi_:
                            parsed[(fname, n, col)] = x
                        else:
                            add(fname, n, col, f"القيمة خارج النطاق ({lo_} إلى {hi_}): {v}", f"Value out of range ({lo_} to {hi_}): {v}")
                elif kind == "num":
                    try:
                        parsed[(fname, n, col)] = parse_num(v)
                    except ValueError:
                        add(fname, n, col, f"يجب أن يكون رقمًا: {v}", f"Not a number: {v}")
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
        if r["crop_id"] and r["crop_id"] in seen:
            add("crop_requirements.csv", n, "crop_id", f"المحصول مكرر: {r['crop_id']}", f"Duplicate crop: {r['crop_id']}")
        seen.add(r["crop_id"])
    seen = set()
    for n, r in tables["crop_stages.csv"]:
        k = (r["crop_id"], r["seq"])
        if r["crop_id"] and r["seq"] and k in seen:
            add("crop_stages.csv", n, "seq", f"المرحلة مكررة: {r['crop_id']} #{r['seq']}", f"Duplicate stage: {r['crop_id']} #{r['seq']}")
        seen.add(k)

    seen = set()
    for n, r in tables["crop_kc_monthly.csv"]:
        k = (r["crop_id"], r["month"])
        if r["crop_id"] and r["month"] and k in seen:
            add("crop_kc_monthly.csv", n, "month", f"الشهر مكرر: {r['crop_id']} #{r['month']}", f"Duplicate month: {r['crop_id']} #{r['month']}")
        seen.add(k)

    # foreign keys
    src, gov, crops = ids("sources.csv"), ids("governorates.csv"), ids("crops.csv")
    for f in FILES[1:]:
        for n, r in tables[f]:
            if r["source_id"] and r["source_id"] not in src and "sources.csv" not in unusable:
                add(f, n, "source_id", f"المصدر غير موجود: {r['source_id']}", f"Unknown source: {r['source_id']}")
    for n, r in tables["wilayats.csv"]:
        if r["governorate_id"] and r["governorate_id"] not in gov and "governorates.csv" not in unusable:
            add("wilayats.csv", n, "governorate_id", f"المحافظة غير موجودة: {r['governorate_id']}", f"Unknown governorate: {r['governorate_id']}")
    for f in ("crop_requirements.csv", "crop_stages.csv", "crop_kc_monthly.csv"):
        for n, r in tables[f]:
            if r["crop_id"] and r["crop_id"] not in crops and "crops.csv" not in unusable:
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
        u = r["url"]
        if u and not u.lower().startswith(("http://", "https://")):
            add("sources.csv", n, "url", f"الرابط يجب أن يبدأ بـ http:// أو https://: {u}",
                f"url must start with http:// or https://: {u}")
        x = val("sources.csv", n, "reliability")
        if x is not None and not 1 <= x <= 3:
            add("sources.csv", n, "reliability", f"الموثوقية يجب أن تكون بين 1 و3: {x}", f"reliability must be 1..3: {x}")

    # requirements
    f = "crop_requirements.csv"
    for n, r in tables[f]:
        # Intentionally stricter than the DB CHECK: any two non-null temperatures
        # must be in order (the DB only constrains rows where all four are set).
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
        if k is not None and not 0 <= k <= Decimal("1.5"):
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
    # monthly kc
    f = "crop_kc_monthly.csv"
    for n, r in tables[f]:
        m = val(f, n, "month")
        if m is not None and not 1 <= m <= 12:
            add(f, n, "month", f"الشهر يجب أن يكون بين 1 و12: {m}", f"month must be within 1..12: {m}")
        k = val(f, n, "kc")
        if k is not None and not 0 <= k <= Decimal("1.5"):
            add(f, n, "kc", f"قيمة kc يجب أن تكون بين 0 و1.5: {k:g}", f"kc must be within 0..1.5: {k:g}")
    return issues


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else Path("data")
    issues = validate_dir(path)
    if issues:
        for i in issues:
            where = f"{i.file}:{i.row}:{i.column}"
            print(f"{where}\n  {i.message_ar}\n  {i.message_en}")
        return 1
    total = sum(len(read_table(path / f)[1]) for f in FILES)
    print(f"OK: {total} rows")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv))
