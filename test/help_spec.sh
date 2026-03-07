#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "help text"
approve "${cli} --help | sed 's/${tmpdir_escaped}/~/g'" "help_text"
approve "${cli} --help | sed 's/${tmpdir_escaped}/~/g' | grep -F -- '--verbose, -V'" "help_text_has_verbose"
