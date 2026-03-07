#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "prune command"
mkdir -p "$tmpdir/.cache/lct/plugins/acme/tool"

it "lists cache directories in dry run mode"
approve "${cli} prune --cache --dry | sed 's/${tmpdir_escaped}/~/g'" "prune_cache_dry_run_lists_cache_dirs"
