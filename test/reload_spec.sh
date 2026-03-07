#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "reload command"
approve "${cli} reload" "reload"
