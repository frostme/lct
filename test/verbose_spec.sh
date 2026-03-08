#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "verbose logging"
approve "${cli} --verbose env list | sed 's/${tmpdir_escaped}/~/g'" "verbose_env_list"
approve "cat $tmpdir/.local/state/lct/debug.log | sed -E 's/${tmpdir_escaped}/~/g; s/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z \\[[^]]+\\] //; s/^\\[[^]]+\\] //'" "verbose_debug_log"
