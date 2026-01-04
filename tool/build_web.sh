#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f ".env" ]]; then
  echo "Missing .env in repo root."
  echo "Create it by copying .env.example -> .env and filling values, or run:"
  echo "  tool/bootstrap_env.sh"
  exit 1
fi

# For local preview, base-href should be /
flutter build web --release --base-href / --dart-define-from-file=.env

