# Share the Postgres fixtures with the data/ tests. supabase/tests/conftest.py also
# auto-loads for its own directory, so import fixtures rather than register a plugin.
from supabase.tests.conftest import committed_db, db, pg_cluster, pg_dsn  # noqa: F401
