#!/usr/bin/env bash
set -euo pipefail

env_file="${SHARE_DIR}/lct/env.yaml"
alias_file="${SHARE_DIR}/lct/alias.yaml"

source "$(dirname "$0")/approvals.bash"
cat <<EOF >>"$env_file"
SAMPLE_KEY: sample-value
EOF

cat <<EOF >>"$alias_file"
ll: ls -la
EOF

describe "reload command"
approve "${cli} reload" "reload"
