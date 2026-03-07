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
