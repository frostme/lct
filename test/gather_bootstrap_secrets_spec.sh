#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "gather and bootstrap secrets flow"

secret_flow_home="$tmpdir/secret-flow"
mkdir -p "$secret_flow_home/.config/lct" "$secret_flow_home/.local/share" "$secret_flow_home/.local/state" "$secret_flow_home/.cache"

cat >"$secret_flow_home/.config/lct/config.yaml" <<'EOF'
remote: null
configs: []
dotfiles: []
other: []
secrets:
  - ~/.claude.json
plugins: []
modules: []
packageManager: brew
EOF

cat >"$secret_flow_home/.claude.json" <<'EOF'
{"api_key":"top-secret"}
EOF

approve "HOME=$secret_flow_home CONFIG_DIR=$secret_flow_home/.config SHARE_DIR=$secret_flow_home/.local/share STATE_DIR=$secret_flow_home/.local/state CACHE_DIR=$secret_flow_home/.cache LCT_SECRET_PASSPHRASE=testpass GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com ${cli} gather --force | sed -E 's/[0-9]{4}\-[0-9]{2}\-[0-9]{2}/<DATE>/g; s/T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/<TIME>/g; s/${tmpdir_escaped}/~/g; s/[0-9]+ file(s)? changed.*/<GIT_COMMIT_SUMMARY>/g; s/[a-f0-9]{7}\.\.[a-f0-9]{7}/<GIT_RANGE>/g; s/\\[main \\(root-commit\\) [a-f0-9]{7}\\]/[main (root-commit) <GIT_HASH>]/g' | sed '/^ create mode /d'" "gather_secrets_encrypt"

approve "ls -A $secret_flow_home/.local/share/lct/remote/secrets" "gather_secrets_files"

rm -f "$secret_flow_home/.claude.json"

approve "HOME=$secret_flow_home CONFIG_DIR=$secret_flow_home/.config SHARE_DIR=$secret_flow_home/.local/share STATE_DIR=$secret_flow_home/.local/state CACHE_DIR=$secret_flow_home/.cache LCT_SECRET_PASSPHRASE=testpass ${cli} bootstrap --force | sed -E 's/${tmpdir_escaped}/~/g'" "bootstrap_secrets_restore"

approve "cat $secret_flow_home/.claude.json" "bootstrap_secrets_contents"
