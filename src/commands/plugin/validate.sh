plugin_path=${args[plugin]}

if ! validate_local_plugin_idempotency "$plugin_path"; then
  exit 1
fi
