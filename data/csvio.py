"""Tolerant CSV reading for files edited in Excel (BOM, CRLF, stray spaces, blank rows)."""
import csv
from pathlib import Path

_INVISIBLE = dict.fromkeys(map(ord, "\u200b\u200e\u200f\ufeff"))
_INVISIBLE[0xA0] = " "


def _clean(cell: str) -> str:
    return cell.translate(_INVISIBLE).strip()


def read_table(path: Path):
    """Return (header, rows, problems).

    rows is [(spreadsheet_row, row_dict)] with header = row 1. Every cell is
    cleaned (invisible characters removed, NBSP -> space, stripped); rows whose
    cells are all empty are dropped. problems is [(row, column, kind)] with kind
    "duplicate_header" or "extra_cells". Raises UnicodeDecodeError for non-UTF-8.
    """
    with Path(path).open(encoding="utf-8-sig", newline="") as f:
        records = list(csv.reader(f))
    if not records:
        return [], [], []
    header = [_clean(h) for h in records[0]]
    problems = []
    seen = set()
    for h in header:
        if h in seen:
            problems.append((1, h, "duplicate_header"))
        seen.add(h)
    out = []
    for n, rec in enumerate(records[1:], start=2):
        cells = [_clean(c) for c in rec]
        if not any(cells):
            continue
        if any(cells[len(header):]):
            problems.append((n, "", "extra_cells"))
        cells = (cells + [""] * len(header))[: len(header)]
        row = {}
        for h, c in zip(header, cells):
            row.setdefault(h, c)
        out.append((n, row))
    return header, out, problems


def read_rows(path: Path) -> list[dict[str, str]]:
    return [row for _, row in read_table(path)[1]]
