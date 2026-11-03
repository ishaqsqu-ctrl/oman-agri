"""Load validated CSV sets as typed Python rows (shared by importer and exporter).

Conversion is driven by data.schema column specs and data.values parsers.
Empty cell -> None; pipe-separated -> list[str].
"""
from pathlib import Path

from .csvio import read_rows
from .schema import COLUMNS, FILES
from .validate import validate_dir
from .values import parse_int, parse_num


def _convert(kind: str, raw: str):
    if raw == "":
        return None
    if kind in ("int", "smallint"):
        return parse_int(raw)
    if kind == "num":
        return parse_num(raw)
    if kind.startswith("enums:"):
        return [p.strip() for p in raw.split("|") if p.strip()]
    return raw


def check(path: Path) -> None:
    issues = validate_dir(path)
    if issues:
        lines = [f"{i.file}:{i.row}:{i.column}: {i.message_en} / {i.message_ar}" for i in issues]
        raise ValueError(f"{len(issues)} validation issue(s):\n" + "\n".join(lines))


def load_table(path: Path, filename: str) -> list[dict]:
    spec = COLUMNS[filename]
    return [{c: _convert(k, r.get(c, "")) for c, k, _ in spec} for r in read_rows(Path(path) / filename)]


def load_all(path: Path) -> dict[str, list[dict]]:
    """Validate, then return {table: typed rows} in FK order."""
    check(path)
    return {f[:-4]: load_table(path, f) for f in FILES}
