#!/usr/bin/env bash
# Idempotent environment setup for Oman Farmer (Flutter + PostgreSQL/PostGIS + Python tools).
set -euo pipefail

FLUTTER_VERSION="3.47.9"
FLUTTER_DIR="$HOME/flutter"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="/usr/lib/postgresql/16/bin:$FLUTTER_DIR/bin:$PATH"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

# --- Flutter ---
installed=""
if [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  installed="$(grep -o '"frameworkVersion": *"[^"]*"' "$FLUTTER_DIR/bin/cache/flutter.version.json" 2>/dev/null | grep -o '[0-9][0-9.]*' || true)"
fi
if [ "$installed" != "$FLUTTER_VERSION" ]; then
  echo ">> Installing Flutter $FLUTTER_VERSION to $FLUTTER_DIR"
  tmp="$(mktemp -d)"
  curl -fSL "$FLUTTER_URL" -o "$tmp/flutter.tar.xz"
  rm -rf "$FLUTTER_DIR"
  tar -xf "$tmp/flutter.tar.xz" -C "$HOME"
  rm -rf "$tmp"
else
  echo ">> Flutter $FLUTTER_VERSION already installed"
fi
# git refuses repos owned by another user / root in containers
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version >/dev/null 2>&1 || true   # triggers first-run setup

# --- PostgreSQL 16 + PostGIS ---
if ! dpkg -s postgresql-16-postgis-3 >/dev/null 2>&1; then
  echo ">> Installing postgresql-16-postgis-3"
  $SUDO apt-get update -y
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y postgresql-16 postgresql-16-postgis-3
else
  echo ">> postgresql-16-postgis-3 already installed"
fi

# --- Python dev dependencies ---
# --break-system-packages: Debian/Ubuntu Python is "externally managed" (PEP 668);
# this container is disposable, so installing system-wide is acceptable.
python3 -m pip install -q --break-system-packages -r "$REPO_ROOT/requirements-dev.txt"

echo
echo "Add to your shell profile:"
echo "  export PATH=\"/usr/lib/postgresql/16/bin:\$HOME/flutter/bin:\$PATH\""
echo
flutter --version 2>&1 | grep -m1 '^Flutter '
pg_config --version
