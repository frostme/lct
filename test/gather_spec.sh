#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "gather command"

gather_home="$tmpdir/gather-home"
mkdir -p "$gather_home/.config/nvim" "$gather_home/.config/lazygit" "$gather_home/.local/share" "$gather_home/work"
touch "$gather_home/.config/nvim/init.lua"
touch "$gather_home/.config/lazygit/config.yml"
touch "$gather_home/.zshrc"
touch "$gather_home/work/custom.conf"

cat >"$gather_home/.config/lct/config.yaml" <<'EOF'
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

it "gathers configured files into the remote repository"
allow_diff "(zsh|bash|Brewfile|brew|apt-packages.txt|apt)"
approve "HOME=$gather_home CONFIG_DIR=$gather_home/.config SHARE_DIR=$gather_home/.local/share STATE_DIR=$gather_home/.local/state CACHE_DIR=$gather_home/.cache GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com ${cli} gather --force | sed -E 's/[0-9]{4}\-[0-9]{2}\-[0-9]{2}/<DATE>/g; s/T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/<TIME>/g; s/${tmpdir_escaped}/~/g; s/[0-9]+ file(s)? changed.*/<GIT_COMMIT_SUMMARY>/g; s/[a-f0-9]{7}\.\.[a-f0-9]{7}/<GIT_RANGE>/g; s/\\[main \\(root-commit\\) [a-f0-9]{7}\\]/[main (root-commit) <GIT_HASH>]/g' | sed '/^ create mode /d'" "gather_force":
