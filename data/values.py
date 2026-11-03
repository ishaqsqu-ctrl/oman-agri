"""Strict value parsers shared by the validator and the importer.

Arabic-Indic digits and the Arabic decimal separator are accepted (the owner
types on an Arabic keyboard) but everything is normalised to plain ASCII and
then matched exactly, so only strings Postgres also accepts get through.
"""
import re
from decimal import Decimal

_TRANS = {0x0660 + i: 0x30 + i for i in range(10)}
_TRANS.update({0x06F0 + i: 0x30 + i for i in range(10)})
_TRANS[0x066B] = ord(".")

_INT = re.compile(r"-?[0-9]+")
_NUM = re.compile(r"-?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)")


def _norm(s: str) -> str:
    return s.strip().translate(_TRANS)


def parse_int(s: str) -> int:
    t = _norm(s)
    if not _INT.fullmatch(t):
        raise ValueError(f"not an integer: {s!r}")
    return int(t)


def parse_num(s: str) -> Decimal:
    t = _norm(s)
    if not _NUM.fullmatch(t):
        raise ValueError(f"not a number: {s!r}")
    return Decimal(t)
