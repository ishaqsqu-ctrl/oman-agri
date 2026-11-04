"""Import a validated CSV set into Postgres. Usage: python -m data.import_db data/ --dsn $DATABASE_URL

Connects as the DB owner/service role (bypasses RLS) - an admin tool.
"""
import argparse
import os
import sys
from pathlib import Path

import psycopg

from .schema import COLUMNS, FILES
from .typed import load_all

PKS = {
    "sources": ["id"], "governorates": ["id"], "wilayats": ["id"], "crops": ["id"],
    "crop_requirements": ["crop_id"], "crop_stages": ["crop_id", "seq"],
    "crop_kc_monthly": ["crop_id", "month"],
}
ENUM_TYPES = {
    "enum:STATUSES": "knowledge_status", "enum:SOURCE_TYPES": "source_type",
    "enum:LIFECYCLES": "lifecycle", "enum:STAGES": "growth_stage",
    "enums:CATEGORIES": "crop_category[]", "enums:TEXTURES": "soil_texture[]",
}


def _placeholder(col: str, kind: str) -> str:
    if col == "reviewed_at":
        return "%s::timestamptz"
    return f"%s::{ENUM_TYPES[kind]}" if kind in ENUM_TYPES else "%s"


def _set_clause(col: str) -> str:
    # The CSV is the single source of truth for status, with one exception: a row
    # the admin already published in the DB (admin-panel shortcut) is not
    # downgraded when the CSV still says "reviewed". A CSV "draft" always wins
    # (explicit retraction by the owner).
    if col == "status":
        return ("status = case when t.status = 'published' and excluded.status = 'reviewed' "
                "then t.status else excluded.status end")
    return f"{col} = excluded.{col}"


def _upsert_sql(table: str, filename: str) -> str:
    spec = COLUMNS[filename]
    cols = [c for c, _, _ in spec]
    pk = PKS[table]
    sets = ", ".join(_set_clause(c) for c in cols if c not in pk)
    return (f"insert into {table} as t ({', '.join(cols)}) "
            f"values ({', '.join(_placeholder(c, k) for c, k, _ in spec)}) "
            f"on conflict ({', '.join(pk)}) do update set {sets}")


def import_dir(path: Path, conn) -> dict[str, int]:
    """Validate and upsert all tables in one transaction (savepoint if one is open).

    Upsert only: a row deleted from the CSV stays in the DB (set status=draft to
    hide it). Status follows the CSV, except published is kept when the CSV says
    reviewed (see _set_clause).

    Raises ValueError (listing issues) before touching the DB if validation fails.
    The caller commits when the connection is not autocommit.
    """
    data = load_all(Path(path))
    counts = {}
    with conn.transaction():
        for f in FILES:
            table = f[:-4]
            cols = [c for c, _, _ in COLUMNS[f]]
            rows = data[table]
            if rows:
                with conn.cursor() as cur:
                    cur.executemany(_upsert_sql(table, f), [[r[c] for c in cols] for r in rows])
            counts[table] = len(rows)
    return counts


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("path", type=Path)
    ap.add_argument("--dsn", default=os.environ.get("DATABASE_URL"))
    a = ap.parse_args(argv)
    if not a.dsn:
        print("error: --dsn or DATABASE_URL required", file=sys.stderr)
        return 2
    try:
        with psycopg.connect(a.dsn) as conn:  # commits on clean exit
            counts = import_dir(a.path, conn)
    except ValueError as e:
        print(e, file=sys.stderr)
        return 1
    for t, n in counts.items():
        print(f"{t}: {n}")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
