"""Build the app's offline knowledge snapshot from CSV (not DB).
Usage: python -m data.export_snapshot data/ [--out app/assets/seed/knowledge.json]
"""
import argparse
import json
import sys
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

from .typed import load_all

DEFAULT_OUT = Path("app/assets/seed/knowledge.json")


def _plain(v):
    if isinstance(v, Decimal):
        return int(v) if v == v.to_integral_value() else float(v)
    return v


def _row(r: dict, drop: str | None = None) -> dict:
    return {k: _plain(v) for k, v in r.items() if k != drop}


def build_snapshot(path: Path, now: str | None = None) -> dict:
    """All rows regardless of status (the app filters). Raises ValueError if invalid."""
    d = load_all(Path(path))
    reqs = {r["crop_id"]: _row(r, "crop_id") for r in d["crop_requirements"]}
    stages: dict[str, list] = {}
    for s in sorted(d["crop_stages"], key=lambda s: s["seq"]):
        stages.setdefault(s["crop_id"], []).append(_row(s, "crop_id"))
    kc_monthly: dict[str, list] = {}
    for m in sorted(d["crop_kc_monthly"], key=lambda m: m["month"]):
        kc_monthly.setdefault(m["crop_id"], []).append(_row(m, "crop_id"))
    crops = [{**_row(c), "requirements": reqs.get(c["id"]), "stages": stages.get(c["id"], []),
              "kc_monthly": kc_monthly.get(c["id"], [])}
             for c in d["crops"]]
    return {
        "schema_version": 1,
        "generated_at": now or datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "sources": [_row(r) for r in d["sources"]],
        "governorates": [_row(r) for r in d["governorates"]],
        "wilayats": [_row(r) for r in d["wilayats"]],
        "crops": crops,
    }


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("path", type=Path)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    a = ap.parse_args(argv)
    try:
        snap = build_snapshot(a.path)
    except ValueError as e:
        print(e, file=sys.stderr)
        return 1
    a.out.parent.mkdir(parents=True, exist_ok=True)
    a.out.write_text(json.dumps(snap, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {a.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
