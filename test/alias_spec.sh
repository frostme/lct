#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "alias command"
it "adds an alias"
approve "${cli} alias add ll 'ls -la'" "alias_add"

it "removes an alias"
approve "${cli} alias remove ll" "alias_remove"
