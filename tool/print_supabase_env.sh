#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "admin-panel/.env.local" ]]; then
  echo "admin-panel/.env.local not found"
  exit 1
fi

# shellcheck disable=SC1091
source "admin-panel/.env.local"

if [[ -z "${VITE_SUPABASE_URL:-}" || -z "${VITE_SUPABASE_ANON_KEY:-}" ]]; then
  echo "Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in admin-panel/.env.local"
  exit 1
fi

cat <<EOF
export SUPABASE_URL='${VITE_SUPABASE_URL}'
export SUPABASE_ANON_KEY='${VITE_SUPABASE_ANON_KEY}'
export SUPABASE_FEED='true'
EOF

