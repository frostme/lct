plugin_name=${args[plugin]}
PLUGINS_DIR=${LCT_SOFTWARE_DIR}/plugins

echo "Creating plugin directory for '${plugin_name}'"
mkdir -p "${PLUGINS_DIR}/${plugin_name}"

echo "Creating initial files for plugin '${plugin_name}'"
cat <<EOF >"${PLUGINS_DIR}/${plugin_name}/README.md"
# ${plugin_name} Plugin for LCT
#
# Describe the purpose and functionality of the plugin here.
Install the ${plugin_name} plugin and configure it as needed.
EOF
cat <<EOF >"${PLUGINS_DIR}/${plugin_name}/main.sh"
# ${plugin_name} Plugin Main Script
# Add your plugin logic here.
EOF
cat <<EOF >"${PLUGINS_DIR}/${plugin_name}/config.yaml"
# ${plugin_name} Plugin Configuration
# Add your plugin configuration options here.
name: ${plugin_name}
version: 0.1.0
filename: main.sh
EOF
echo "✅ Plugin '${plugin_name}' created successfully in '${PLUGINS_DIR}/${plugin_name}'"
