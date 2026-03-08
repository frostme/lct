#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$CONFIG_DIR/lct" "$SHARE_DIR/lct" "$STATE_DIR/lct" "$CACHE_DIR/lct"

cat >"$CONFIG_DIR/lct/config.yaml" <<'EOF'
remote: null
configs: []
dotfiles: []
other: []
plugins: []
modules: []
projects: []
EOF

touch "$SHARE_DIR/lct/env.yaml" "$SHARE_DIR/lct/alias.yaml" "$STATE_DIR/lct/debug.log"
