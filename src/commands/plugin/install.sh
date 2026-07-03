plugin=${args[plugin]:-}
requested_version=${args[--version]:-}
force_install=${args[--force]:-0}
PLUGIN_INSTALL_FORCE="$force_install"
lct_log_debug "plugin install command started (plugin=${plugin:-<all>}, version=${requested_version:-<configured>}, force=${force_install})"

rewrite_config_plugins() {
  local plugin_entries=("$@")
  yq -i '.plugins = []' "$LCT_CONFIG_FILE"
  for plugin_entry in "${plugin_entries[@]}"; do
    FIELD_VALUE="$plugin_entry" yq -i '.plugins += [env(FIELD_VALUE)]' "$LCT_CONFIG_FILE"
  done
}

if [[ -n "$plugin" ]]; then
  plugin_cli_ref_parse "$plugin" plugin_name cli_version
  if [[ -n "$requested_version" && -n "$cli_version" ]]; then
    echo "❌ ERROR: Specify the plugin version either with @version or --version, not both." >&2
    exit 1
  fi
  [[ -z "$requested_version" ]] && requested_version="$cli_version"

  if ! plugin_ref_is_valid "$plugin_name"; then
    echo "❌ ERROR: Plugin must be in owner/repo or owner/repo.name format" >&2
    exit 1
  fi

  if [[ ! -f "$LCT_CONFIG_FILE" ]]; then
    echo "❌ ERROR: config.yaml file not found at ${LCT_CONFIG_FILE}" >&2
    exit 1
  fi

  plugin_slug=$(plugin_key_slug "$plugin_name")
  plugin_exists=0
  existing_entry=""

  while IFS= read -r configured_plugin; do
    [[ -z "$configured_plugin" ]] && continue
    plugin_parse_entry "$configured_plugin" configured_name configured_version
    if [[ "$(plugin_key_slug "$configured_name")" == "$plugin_slug" ]]; then
      plugin_exists=1
      existing_entry="$configured_plugin"
      [[ -z "$requested_version" ]] && requested_version="$configured_version"
      break
    fi
  done < <(yq -r '.plugins[]?' "$LCT_CONFIG_FILE" 2>/dev/null)

  plugin_entry="$(plugin_format_entry "$plugin_name" "$requested_version")"
  if [[ $plugin_exists -eq 0 ]]; then
    append_unique "plugins" "$plugin_entry"
  elif [[ "$existing_entry" != "$plugin_entry" ]]; then
    mapfile -t updated_plugins < <(
      while IFS= read -r listed_plugin; do
        [[ -z "$listed_plugin" ]] && continue
        plugin_parse_entry "$listed_plugin" listed_name _
        if [[ "$(plugin_key_slug "$listed_name")" == "$plugin_slug" ]]; then
          printf '%s\n' "$plugin_entry"
        else
          printf '%s\n' "$listed_plugin"
        fi
      done < <(yq -r '.plugins[]?' "$LCT_CONFIG_FILE" 2>/dev/null) | awk '!seen[$0]++'
    )
    rewrite_config_plugins "${updated_plugins[@]}"
  fi

  PLUGINS=("$plugin_entry")
elif [[ -n "$requested_version" ]]; then
  echo "❌ ERROR: --version requires a plugin argument." >&2
  exit 1
fi

plugin_installation
load_plugins
lct_log_info "plugin install command completed"
