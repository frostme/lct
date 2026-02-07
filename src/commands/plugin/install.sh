plugin=${args[plugin]:-}

if [[ -n "$plugin" ]]; then
  if [[ "$plugin" != */* ]]; then
    echo "❌ ERROR: Plugin must be in owner/repo or owner/repo.name format" >&2
    exit 1
  fi

  if [[ ! -f "$LCT_CONFIG_FILE" ]]; then
    echo "❌ ERROR: config.yaml file not found at ${LCT_CONFIG_FILE}" >&2
    exit 1
  fi

  plugin_slug=$(plugin_key_slug "$plugin")
  plugin_exists=0

  while IFS= read -r configured_plugin; do
    [[ -z "$configured_plugin" ]] && continue
    if [[ "$(plugin_key_slug "$configured_plugin")" == "$plugin_slug" ]]; then
      plugin_exists=1
      break
    fi
  done < <(yq -r '.plugins[]?' "$LCT_CONFIG_FILE" 2>/dev/null)

  if [[ $plugin_exists -eq 0 ]]; then
    append_unique "plugins" "$plugin"
  fi

  PLUGINS=("$plugin")
fi

plugin_installation
load_plugins
