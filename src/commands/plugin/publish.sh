plugin_name=${args[plugin]}
PLUGINS_DIR=${LCT_SOFTWARE_DIR}/plugins
PLUGIN_DIR="${PLUGINS_DIR}/${plugin_name}"
PLUGIN_CONFIG_FILE="${PLUGIN_DIR}/config.yaml"
PLUGIN_VERSION=$(yq '.version' "$PLUGIN_CONFIG_FILE")
PLUGIN_FILENAME=$(yq '.filename' "$PLUGIN_CONFIG_FILE")
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/$plugin_name/src"
mkdir -p "$TMP_DIR/$plugin_name/target"

git clone -q "$REGISTRY" "$TMP_DIR/registry"

echo "Packaging plugin '${plugin_name}' version '${PLUGIN_VERSION}'"
cp -r "$PLUGIN_DIR/$PLUGIN_FILENAME" "$TMP_DIR/$plugin_name/src/"
PLUGIN_DESCRIPTION=$(cat $PLUGIN_DIR/README.md | sed 's/^/  /')

cat <<EOF >"${TMP_DIR}/${plugin_name}/src/bashly.yml"
name: ${plugin_name}
version: ${PLUGIN_VERSION}
help: |
  ${plugin_name} Plugin for LCT
${PLUGIN_DESCRIPTION}
filename: ${PLUGIN_FILENAME}
EOF

cat <<EOF >"${TMP_DIR}/${plugin_name}/settings.yml"
target_dir: target
partials_extension: sh
strict: set -Eeuo pipefail
tab_indent: false
word_wrap: 80
formatter: internal
EOF

cat <<EOF >"${TMP_DIR}/${plugin_name}/src/header.sh"
#!/usr/bin/env bash
EOF

cd "$TMP_DIR/$plugin_name"

echo "Validating Plugin Bashly configuration"
bashly validate
echo "Generating Plugin Bashly files"
bashly generate
mv target/${plugin_name} target/${plugin_name}-${PLUGIN_VERSION}
echo "Packaging Plugin into tar.xz archive"
tar -cJf "$TMP_DIR/registry/plugins/${plugin_name}-${PLUGIN_VERSION}.tar.xz" -C "$TMP_DIR/$plugin_name/target" "${plugin_name}-${PLUGIN_VERSION}"
echo "Publishing Plugin to registry"
# TODO: change to publishing to a central repo
cd "$TMP_DIR/registry"
git add .
git commit -m "Publish plugin ${plugin_name} version ${PLUGIN_VERSION}" || echo "No changes to commit"
git push origin main || echo "No remote repository configured, skipping push"
echo "✅ Plugin '${plugin_name}' version '${PLUGIN_VERSION}' published successfully"
