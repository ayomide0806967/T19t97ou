#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEVICE="${1:-}"

if [[ -z "${DEVICE}" ]]; then
  echo "Usage: tool/run_live_android.sh <device-id>"
  echo "Example: tool/run_live_android.sh 192.168.0.147:5555"
  exit 2
fi

if [[ ! -f ".env" ]]; then
  echo "Missing .env in repo root."
  echo "Create it by copying .env.example -> .env and filling values, or run:"
  echo "  tool/bootstrap_env.sh"
  exit 1
fi

flutter run \
  -d "${DEVICE}" \
  --dart-define-from-file=.env
