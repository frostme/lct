#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "gather command secret detection"

secret_home="$tmpdir/secret-home"
mkdir -p "$secret_home/.config/lct" "$secret_home/.local/share" "$secret_home/work"

cat >"$secret_home/.config/lct/config.yaml" <<'EOF'
remote: null
configs: []
dotfiles: []
other:
  - ~/work/claude.json
plugins: []
modules: []
EOF

cat >"$secret_home/work/claude.json" <<'EOF'
{
  "api_key": "sk-test-123",
  "authorization": "Bearer secret",
  "name": "demo"
}
EOF

it "scrubs detected secrets when requested"
allow_diff "(zsh|bash|Brewfile|brew|apt-packages.txt|apt)"
approve "HOME=$secret_home CONFIG_DIR=$secret_home/.config SHARE_DIR=$secret_home/.local/share STATE_DIR=$secret_home/.local/state CACHE_DIR=$secret_home/.cache LCT_GATHER_SECRET_ACTION=scrub GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com ${cli} gather --force | sed -E 's/[0-9]{4}\-[0-9]{2}\-[0-9]{2}/<DATE>/g; s/T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/<TIME>/g; s/${tmpdir_escaped}/~/g; s/[0-9]+ file(s)? changed.*/<GIT_COMMIT_SUMMARY>/g; s/[a-f0-9]{7}\.\.[a-f0-9]{7}/<GIT_RANGE>/g; s/\\[main \\(root-commit\\) [a-f0-9]{7}\\]/[main (root-commit) <GIT_HASH>]/g' | sed '/^ create mode /d'" "gather_scrub_secrets":

approve "if [[ ! -f $secret_home/.local/share/lct/remote/other/work/claude.json ]]; then echo 'secret file scrubbed'; else echo 'secret file still present'; fi" "gather_scrub_secrets_result"
