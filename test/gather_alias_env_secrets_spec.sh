#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "gather and bootstrap alias/env secrets flow"

secret_home="$tmpdir/alias-env-secrets"
mkdir -p "$secret_home/.config/lct" "$secret_home/.local/share/lct" "$secret_home/.local/state" "$secret_home/.cache"

cat >"$secret_home/.config/lct/config.yaml" <<'EOF'
remote: null
configs: []
dotfiles: []
other: []
secrets: []
plugins: []
modules: []
packageManager: brew
encryptAliasFile: true
encryptEnvFile: true
EOF

cat >"$secret_home/.local/share/lct/alias.yaml" <<'EOF'
ll: ls -la
EOF

cat >"$secret_home/.local/share/lct/env.yaml" <<'EOF'
HELLO: world
EOF

approve "HOME=$secret_home CONFIG_DIR=$secret_home/.config SHARE_DIR=$secret_home/.local/share STATE_DIR=$secret_home/.local/state CACHE_DIR=$secret_home/.cache LCT_SECRET_PASSPHRASE=testpass GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com ${cli} gather --force | sed -E 's/[0-9]{4}\\-[0-9]{2}\\-[0-9]{2}/<DATE>/g; s/T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/<TIME>/g; s/${tmpdir_escaped}/~/g; s/[0-9]+ file(s)? changed.*/<GIT_COMMIT_SUMMARY>/g; s/[a-f0-9]{7}\.\.[a-f0-9]{7}/<GIT_RANGE>/g; s/\\[main \\(root-commit\\) [a-f0-9]{7}\\]/[main (root-commit) <GIT_HASH>]/g' | sed '/^ create mode /d'" "gather_alias_env_secrets_encrypt"

approve "ls -A $secret_home/.local/share/lct/remote/secrets | sort" "gather_alias_env_secrets_files"

rm -f "$secret_home/.local/share/lct/alias.yaml" "$secret_home/.local/share/lct/env.yaml"

approve "HOME=$secret_home CONFIG_DIR=$secret_home/.config SHARE_DIR=$secret_home/.local/share STATE_DIR=$secret_home/.local/state CACHE_DIR=$secret_home/.cache LCT_SECRET_PASSPHRASE=testpass ${cli} bootstrap --force | sed -E 's/${tmpdir_escaped}/~/g'" "bootstrap_alias_env_secrets_restore"

approve "cat $secret_home/.local/share/lct/alias.yaml" "bootstrap_alias_secret_contents"

approve "cat $secret_home/.local/share/lct/env.yaml" "bootstrap_env_secret_contents"
