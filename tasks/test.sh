#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v bashly >/dev/null 2>&1; then
  echo "bashly is required to run tests. Run ./setup.sh to install it." >&2
  exit 1
fi

cd "$repo_root"

bashly validate
bashly generate --upgrade

if [ ! -x target/build/lct ]; then
  echo "Generated CLI missing at target/build/lct" >&2
  exit 1
fi

target/build/lct --help >/dev/null

echo "Smoke tests passed."
