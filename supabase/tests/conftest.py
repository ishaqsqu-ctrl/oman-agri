"""Throwaway Postgres 16 cluster for schema/RLS tests.

initdb refuses to run as root, so when the test process is root the cluster is
owned by and run as the unprivileged `postgres` OS user (via `runuser`).
Connections go over TCP on localhost (trust auth) as the `postgres` superuser.
"""
import contextlib
import glob
import os
import shutil
import socket
import subprocess
import tempfile
from pathlib import Path

import psycopg
import pytest

PG_BIN = "/usr/lib/postgresql/16/bin"
HERE = Path(__file__).resolve().parent
MIGRATIONS = HERE.parent / "migrations"


def _free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def _run(cmd, as_postgres):
    if as_postgres and os.geteuid() == 0:
        cmd = ["runuser", "-u", "postgres", "--"] + cmd
    subprocess.run(cmd, check=True, capture_output=True, text=True)


@pytest.fixture(scope="session")
def pg_dsn():
    # Not tmp_path_factory: pytest's base dir is 0700 root, which the postgres
    # OS user could not traverse.
    root = Path(tempfile.mkdtemp(prefix="omanfarmer-pg-"))
    data = root / "data"
    is_root = os.geteuid() == 0
    if is_root:
        shutil.chown(root, "postgres", "postgres")
        os.chmod(root, 0o755)
    port = _free_port()
    _run([f"{PG_BIN}/initdb", "-D", str(data), "-U", "postgres", "-A", "trust",
          "--no-sync"], is_root)
    _run([f"{PG_BIN}/pg_ctl", "-D", str(data), "-w", "-l", str(root / "pg.log"),
          "-o", f"-p {port} -h 127.0.0.1 -k {root} -c fsync=off", "start"], is_root)
    dsn = f"host=127.0.0.1 port={port} user=postgres dbname=postgres"
    try:
        with psycopg.connect(dsn, autocommit=True) as conn:
            conn.execute((HERE / "auth_stub.sql").read_text())
            for f in sorted(glob.glob(str(MIGRATIONS / "*.sql"))):
                conn.execute(Path(f).read_text())
        yield dsn
    finally:
        _run([f"{PG_BIN}/pg_ctl", "-D", str(data), "-m", "immediate", "stop"], is_root)
        shutil.rmtree(root, ignore_errors=True)


@pytest.fixture
def db(pg_dsn):
    """Superuser connection inside a transaction that is rolled back per test."""
    conn = psycopg.connect(pg_dsn)
    try:
        yield conn
    finally:
        conn.rollback()
        conn.close()


@contextlib.contextmanager
def as_role(conn, role: str, uid: str | None = None):
    """Run statements as `role` (and JWT sub `uid`) for the enclosed block.

    Uses SET LOCAL semantics inside the connection's open transaction; the
    role and claim are reset on exit.
    """
    conn.execute(f'set local role "{role}"')
    conn.execute("select set_config('request.jwt.claim.sub', %s, true)", [uid or ""])
    try:
        yield conn
    finally:
        conn.execute("reset role")
        conn.execute("select set_config('request.jwt.claim.sub', '', true)")
