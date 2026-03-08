#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "project command"
cat >"$tmpdir/.config/lct/config.yaml" <<'EOF'
remote: null
configs: []
dotfiles: []
other: []
plugins: []
modules: []
projects: []
EOF

project_workdir="$tmpdir/work-project"
mkdir -p "$project_workdir"
git -C "$project_workdir" init -q
git -C "$project_workdir" config user.email "test@example.com"
git -C "$project_workdir" config user.name "Test User"
git -C "$project_workdir" remote add origin "git@github.com:frostme/lct.git"

pushd "$project_workdir" >/dev/null
approve "${cli} project list" "project_list_empty"
approve "${cli} project add" "project_add"
approve "${cli} project add" "project_add_idempotent"
approve "${cli} project list" "project_list_after_add"
approve "${cli} project remove" "project_remove"
approve "${cli} project list" "project_list_after_remove"
popd >/dev/null
