"""Tolerant CSV reading for files edited in Excel (BOM, CRLF, stray spaces, blank rows)."""
import csv
from pathlib import Path


def read_table(path: Path) -> tuple[list[str], list[tuple[int, dict[str, str]]]]:
    """Return (header, [(spreadsheet_row, row_dict)]); header is row 1.

    Every cell is stripped; rows whose cells are all empty are dropped.
    """
    with Path(path).open(encoding="utf-8-sig", newline="") as f:
        records = list(csv.reader(f))
    if not records:
        return [], []
    header = [h.strip() for h in records[0]]
    out = []
    for n, rec in enumerate(records[1:], start=2):
        cells = [c.strip() for c in rec]
        if not any(cells):
            continue
        cells = (cells + [""] * len(header))[: max(len(header), len(cells))]
        row = {h: cells[i] for i, h in enumerate(header)}
        out.append((n, row))
    return header, out


def read_rows(path: Path) -> list[dict[str, str]]:
    return [row for _, row in read_table(path)[1]]
