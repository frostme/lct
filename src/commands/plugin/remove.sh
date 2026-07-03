plugin=${args[plugin]}
plugin_cli_ref_parse "$plugin" plugin_name _
plugin_slug=$(plugin_key_slug "$plugin_name")
plugin_dir="$(plugin_install_dir "$plugin_name")"

if [[ ! -d "$plugin_dir" ]]; then
  echo "❌ ERROR: Plugin '${plugin_name}' is not installed." >&2
  exit 1
fi

rm -rf -- "$plugin_dir"
echo "Removed plugin ${plugin_name}"

if [[ -f "$LCT_CONFIG_FILE" ]]; then
  mapfile -t remaining_plugins < <(
    while IFS= read -r configured_plugin; do
      [[ -z "$configured_plugin" ]] && continue
      plugin_parse_entry "$configured_plugin" configured_name _
      [[ "$(plugin_key_slug "$configured_name")" == "$plugin_slug" ]] && continue
      printf '%s\n' "$configured_plugin"
    done < <(yq -r '.plugins[]?' "$LCT_CONFIG_FILE" 2>/dev/null) | awk '!seen[$0]++'
  )
  rewrite_config_plugins "${remaining_plugins[@]}"
fi

if [[ ${#PLUGINS[@]} -gt 0 ]]; then
  mapfile -t PLUGINS < <(
    printf '%s\n' "${PLUGINS[@]}" |
      while IFS= read -r configured_plugin; do
        [[ -z "$configured_plugin" ]] && continue
        [[ "$(plugin_key_slug "$configured_plugin")" == "$plugin_slug" ]] && continue
        printf '%s\n' "$configured_plugin"
      done
  )
fi
