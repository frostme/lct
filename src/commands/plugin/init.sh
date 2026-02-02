plugin_dir=${PWD}
plugin_name=$(basename "${plugin_dir}")

echo "Creating initial files for plugin '${plugin_name}'"

if [ ! -f "${plugin_dir}/README.md" ]; then
  cat <<EOF >"${plugin_dir}/README.md"
# ${plugin_name} Plugin for LCT
#
# Describe the purpose and functionality of the plugin here.
Install the ${plugin_name} plugin and configure it as needed.
EOF
fi

if [ ! -f "${plugin_dir}/main.sh" ]; then
  cat <<EOF >"${plugin_dir}/main.sh"
# ${plugin_name} Plugin Main Script
# Add your plugin logic here.
EOF
fi

echo "✅ Plugin '${plugin_name}' init successful"
