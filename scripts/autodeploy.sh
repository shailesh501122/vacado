#!/usr/bin/env bash
# Vacado auto-deploy poller.
# Runs every minute via systemd timer. Pulls main, runs npm install + migrate
# only if anything changed, then restarts the API. Logs to journald.

set -euo pipefail

REPO=/opt/vacado
cd "$REPO"

git fetch --quiet origin main
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
  exit 0
fi

echo "[autodeploy] $LOCAL → $REMOTE"

# Find out which files changed so we only re-install / re-migrate when needed.
CHANGED=$(git diff --name-only "$LOCAL" "$REMOTE")
NEEDS_INSTALL=0
NEEDS_MIGRATE=0
NEEDS_SEED_STAFF=0

echo "$CHANGED" | grep -qE '^backend/package(-lock)?\.json$'      && NEEDS_INSTALL=1 || true
echo "$CHANGED" | grep -qE '^backend/migrations/'                 && NEEDS_MIGRATE=1 || true
echo "$CHANGED" | grep -qE '^backend/src/db/seedStaff\.js$|^backend/migrations/004_'        && NEEDS_SEED_STAFF=1 || true

git reset --hard origin/main

cd "$REPO/backend"

if [ "$NEEDS_INSTALL" = "1" ]; then
  echo "[autodeploy] npm install"
  npm install --omit=dev --no-audit --no-fund
fi

if [ "$NEEDS_MIGRATE" = "1" ]; then
  echo "[autodeploy] migrate"
  node src/db/migrate.js
fi

if [ "$NEEDS_SEED_STAFF" = "1" ]; then
  echo "[autodeploy] seed staff (idempotent)"
  node src/db/seedStaff.js || true
fi

echo "[autodeploy] restart vacado-api"
sudo systemctl restart vacado-api

echo "[autodeploy] done"
