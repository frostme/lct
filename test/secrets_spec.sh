#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "secrets command"
touch "$tmpdir/.claude.json"

it "manages secret paths"
approve "${cli} secrets add ~/.claude.json" "secrets_add"
approve "${cli} secrets list" "secrets_list_after_add"
approve "${cli} secrets remove ~/.claude.json" "secrets_remove"
approve "${cli} secrets list" "secrets_list_after_remove"

it "rejects absolute secret paths"
approve "${cli} secrets add /etc/passwd" "secrets_add_reject_absolute"
