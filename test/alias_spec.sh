#!/usr/bin/env bash
set -euo pipefail

env_file="${SHARE_DIR}/lct/env.yaml"

cat <<EOF >>"$env_file"
SAMPLE_KEY: sample-value
EOF

source "$(dirname "$0")/approvals.bash"

describe "alias command"
it "lists aliases when none exist"
approve "${cli} alias list" "alias_list_empty"

it "adds an alias"
approve "${cli} alias add ll 'ls -la'" "alias_add"

it "lists configured aliases"
approve "${cli} alias list" "alias_list_after_add"

it "removes an alias"
approve "${cli} alias remove ll" "alias_remove"
