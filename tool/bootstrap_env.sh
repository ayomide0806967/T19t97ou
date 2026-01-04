#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".env" ]]; then
  if [[ "${1:-}" != "--force" ]]; then
    echo ".env already exists; not overwriting."
    echo "Re-run with: tool/bootstrap_env.sh --force"
    exit 0
  fi
fi

if [[ ! -f "admin-panel/.env.local" ]]; then
  echo "admin-panel/.env.local not found."
  echo "Create .env manually by copying .env.example -> .env"
  exit 1
fi

# shellcheck disable=SC1091
source "admin-panel/.env.local"

if [[ -z "${VITE_SUPABASE_URL:-}" || -z "${VITE_SUPABASE_ANON_KEY:-}" ]]; then
  echo "admin-panel/.env.local is missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY."
  exit 1
fi

umask 077
cat > .env <<EOF
SUPABASE_URL=${VITE_SUPABASE_URL}
SUPABASE_ANON_KEY=${VITE_SUPABASE_ANON_KEY}
SUPABASE_FEED=true
EOF

echo "Wrote .env (permissions 600)."
