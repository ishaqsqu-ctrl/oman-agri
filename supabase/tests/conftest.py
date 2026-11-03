"""Throwaway Postgres 16 cluster for schema/RLS tests.

initdb refuses to run as root, so when the test process is root the cluster is
owned by and run as the unprivileged `postgres` OS user (via `runuser`).
Connections go over TCP on localhost (trust auth) as the `postgres` superuser.
"""
import contextlib
import glob
import itertools
import os
import shutil
import socket
import subprocess
import tempfile
from pathlib import Path

import psycopg
from psycopg.pq import TransactionStatus
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


def _dsn(port, dbname):
    return f"host=127.0.0.1 port={port} user=postgres dbname={dbname}"


@pytest.fixture(scope="session")
def pg_cluster():
    """Start the cluster; build `template_db` (auth_stub + all migrations) once.

    Yields the port. Roles are cluster-global, so the stub is loaded only once,
    into the template; every test database is cloned from it.
    """
    is_root = os.geteuid() == 0
    # Not tmp_path_factory: pytest's base dir is 0700 root, which the postgres
    # OS user could not traverse.
    root = Path(tempfile.mkdtemp(prefix="omanfarmer-pg-"))
    data = root / "data"
    port = _free_port()
    try:
        if is_root:
            shutil.chown(root, "postgres", "postgres")
            os.chmod(root, 0o755)
        _run([f"{PG_BIN}/initdb", "-D", str(data), "-U", "postgres", "-A", "trust",
              "--no-sync"], is_root)
        _run([f"{PG_BIN}/pg_ctl", "-D", str(data), "-w", "-l", str(root / "pg.log"),
              "-o", f"-p {port} -h 127.0.0.1 -k {root} -c fsync=off", "start"], is_root)
        with psycopg.connect(_dsn(port, "postgres"), autocommit=True) as conn:
            conn.execute("create database template_db")
        with psycopg.connect(_dsn(port, "template_db"), autocommit=True) as conn:
            conn.execute((HERE / "auth_stub.sql").read_text())
            for f in sorted(glob.glob(str(MIGRATIONS / "*.sql"))):
                conn.execute(Path(f).read_text())
        yield port
    finally:
        if (data / "postmaster.pid").exists():
            _run([f"{PG_BIN}/pg_ctl", "-D", str(data), "-m", "immediate", "stop"], is_root)
        shutil.rmtree(root, ignore_errors=True)


def _clone(port, name):
    with psycopg.connect(_dsn(port, "postgres"), autocommit=True) as admin:
        admin.execute(f'create database "{name}" template template_db')


@pytest.fixture(scope="session")
def pg_dsn(pg_cluster):
    """DSN of the shared database used by `db` (never committed to)."""
    _clone(pg_cluster, "shared")
    return _dsn(pg_cluster, "shared")


@pytest.fixture
def db(pg_dsn):
    """Use for tests that do NOT commit (constraints, RLS, triggers).

    Superuser connection inside a transaction rolled back after each test.
    """
    conn = psycopg.connect(pg_dsn)
    try:
        conn.execute("select 1")  # open the transaction so as_role uses a savepoint
        yield conn
    finally:
        conn.rollback()
        conn.close()


_counter = itertools.count()


@pytest.fixture
def committed_db(pg_cluster):
    """Use for code that commits (importer, CLI): a fresh migrated database
    cloned from the template for each test, dropped afterwards. Yields a
    superuser connection (non-autocommit; the code under test may commit)."""
    name = f"t_{os.getpid()}_{next(_counter)}"
    _clone(pg_cluster, name)
    conn = psycopg.connect(_dsn(pg_cluster, name))
    try:
        yield conn
    finally:
        conn.close()
        with psycopg.connect(_dsn(pg_cluster, "postgres"), autocommit=True) as admin:
            admin.execute(f'drop database if exists "{name}" with (force)')


@contextlib.contextmanager
def as_role(conn, role: str, uid: str | None = None):
    """Run statements as `role` (and JWT sub `uid`) for the enclosed block.

    The block runs inside a savepoint. If a statement in it fails (even when the
    test catches the error with pytest.raises, leaving the transaction aborted)
    or the block raises, we ROLLBACK TO the savepoint, which restores role and
    claim and makes the transaction usable again; the original exception
    propagates unchanged. On clean exit, role and claim are reset explicitly.
    Requires an open transaction (the `db` fixture guarantees this).
    """
    conn.execute("savepoint as_role")
    ok = False
    try:
        conn.execute(f'set local role "{role}"')
        conn.execute("select set_config('request.jwt.claim.sub', %s, true)", [uid or ""])
        yield conn
        ok = conn.info.transaction_status != TransactionStatus.INERROR
    finally:
        if ok:
            conn.execute("reset role")
            conn.execute("select set_config('request.jwt.claim.sub', '', true)")
            conn.execute("release savepoint as_role")
        else:
            conn.execute("rollback to savepoint as_role")
            conn.execute("release savepoint as_role")
