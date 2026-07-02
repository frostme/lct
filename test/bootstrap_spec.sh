#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "bootstrap command"

mkdir -p "$tmpdir/.config/nvim" "$tmpdir/.config/lazygit" "$tmpdir/.local/share" "$tmpdir/work"
touch "$tmpdir/.config/nvim/init.lua"
touch "$tmpdir/.config/lazygit/config.yml"
touch "$tmpdir/.zshrc"
touch "$tmpdir/work/custom.conf"

cat >"$tmpdir/.config/lct/config.yaml" <<'EOF'
remote: null
configs:
  - nvim
  - lazygit
dotfiles:
  - ~/.zshrc
other:
  - ~/work/custom.conf
plugins: []
modules: []
packageManager: brew
EOF

GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com "${cli}" gather --force >/dev/null

it "shows bootstrap help"
approve "${cli} bootstrap --help" "bootstrap_help"

it "bootstraps from gathered remote repository"
approve "${cli} bootstrap --force | sed -E 's/${tmpdir_escaped}/~/g'" "bootstrap_force"

it "uses the default bootstrap order"
approve "${cli} bootstrap --force 2>&1 | grep '^Bootstrap execution order:'" "bootstrap_default_order"

it "uses a custom bootstrap order"
yq -i '.bootstrap_order = ["configs", "packages", "projects", "plugins", "modules", "secrets"]' "$tmpdir/.local/share/lct/remote/config.yaml"
approve "${cli} bootstrap --force 2>&1 | grep -E '^(Bootstrap execution order:.*|Applying library configs|Installing package manager dependencies)$'" "bootstrap_custom_order"

it "rejects an invalid bootstrap order"
yq -i '.bootstrap_order = ["packages", "configs", "projects", "plugins", "modules", "unknown"]' "$tmpdir/.local/share/lct/remote/config.yaml"
approve "${cli} bootstrap --force 2>&1 | sed -E 's/${tmpdir_escaped}/~/g'" "bootstrap_invalid_order"
expect_exit_code 1

it "bootstraps using non-brew package bundle when present"
rm -f "$tmpdir/.local/share/lct/remote/Brewfile"
cat >"$tmpdir/.local/share/lct/remote/apt-packages.txt" <<'EOF'
ripgrep
fd-find
EOF
cat >"$tmpdir/.local/share/lct/remote/config.yaml" <<'EOF'
remote: null
configs:
  - nvim
dotfiles:
  - ~/.zshrc
other:
  - ~/work/custom.conf
plugins: []
modules: []
packageManager: apt
EOF
approve "${cli} bootstrap --force | sed -E 's/${tmpdir_escaped}/~/g'" "bootstrap_force_apt_bundle"

it "clones configured projects during bootstrap"
rm -rf "$tmpdir/.local/share/lct/remote"
mkdir -p "$tmpdir/.local/share/lct/remote/configs/nvim"
cat >"$tmpdir/.local/share/lct/remote/configs/nvim/init.lua" <<'EOF'
print("init")
EOF
cat >"$tmpdir/.local/share/lct/remote/config.yaml" <<'EOF'
remote: null
configs:
  - nvim
dotfiles: []
other: []
plugins: []
modules: []
projects:
  - example/demo
EOF
cat >"$tmpdir/.config/lct/config.yaml" <<'EOF'
remote: null
configs:
  - nvim
dotfiles: []
other: []
plugins: []
modules: []
projects:
  - example/demo
EOF
rm -rf "$tmpdir/code"
project_clone_repo="$tmpdir/mock-github/example/demo.git"
mkdir -p "$project_clone_repo"
git -C "$project_clone_repo" init -q
git -C "$project_clone_repo" config user.email "test@example.com"
git -C "$project_clone_repo" config user.name "Test User"
cat >"$project_clone_repo/README.md" <<'EOF'
# demo
EOF
git -C "$project_clone_repo" add README.md
git -C "$project_clone_repo" commit -q -m "initial"

approve "${cli} bootstrap --force | sed -E 's/${tmpdir_escaped}/~/g'" "bootstrap_projects"
approve "ls -1 $tmpdir/code" "bootstrap_projects_clone"

it "skips expected existing state on a repeated bootstrap"
if ! output="$(${cli} bootstrap 2>&1)"; then
  fail "expected repeated bootstrap to succeed"
fi
if [[ "$output" != *"nvim config already exists; skipping"* ]] || [[ "$output" != *"example/demo already exists; skipping"* ]]; then
  fail "expected repeated bootstrap to report skipped config and project state"
fi
pass "repeated bootstrap skips expected existing state"

it "rejects a conflicting non-repository project directory"
rm -rf "$tmpdir/code/demo"
mkdir -p "$tmpdir/code/demo"
touch "$tmpdir/code/demo/partial-download"
if output="$(${cli} bootstrap --force 2>&1)"; then
  fail "expected bootstrap to reject a conflicting project directory"
fi
if [[ "$output" != *"exists and is not a Git repository"* ]] || [[ "$output" != *"Move or remove it, then rerun lct bootstrap."* ]]; then
  fail "expected actionable project conflict guidance"
fi
pass "conflicting project directory is rejected with recovery guidance"

it "rejects a conflicting config path without force"
yq -i '.projects = []' "$tmpdir/.config/lct/config.yaml"
yq -i '.projects = []' "$tmpdir/.local/share/lct/remote/config.yaml"
rm -rf "$tmpdir/.config/nvim"
touch "$tmpdir/.config/nvim"
if output="$(${cli} bootstrap 2>&1)"; then
  fail "expected bootstrap to reject a conflicting config path"
fi
if [[ "$output" != *"exists and is not a directory"* ]] || [[ "$output" != *"Rerun with --force to replace it."* ]]; then
  fail "expected actionable config conflict guidance"
fi
pass "conflicting config path is rejected with recovery guidance"

it "reports a missing gathered config source"
rm -rf "$tmpdir/.config/nvim"
rm -rf "$tmpdir/.local/share/lct/remote/configs/nvim"
if output="$(${cli} bootstrap --force 2>&1)"; then
  fail "expected bootstrap to reject a missing gathered config source"
fi
if [[ "$output" != *"is missing or is not a directory"* ]] || [[ "$output" != *"Run 'lct gather --force' on the source machine"* ]]; then
  fail "expected actionable missing config source guidance"
fi
pass "missing gathered config source is rejected with recovery guidance"
