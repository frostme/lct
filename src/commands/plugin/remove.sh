plugin=${args[plugin]}
plugin_slug=$(plugin_key_slug "$plugin")
plugin_dir="$LCT_PLUGINS_DIR/$plugin_slug"

if [[ ! -d "$plugin_dir" ]]; then
  echo "❌ ERROR: Plugin '${plugin}' is not installed." >&2
  exit 1
fi

rm -rf -- "$plugin_dir"
echo "Removed plugin ${plugin}"

if [[ -f "$LCT_CONFIG_FILE" ]]; then
  FILTER_SLUG="$plugin_slug" yq -i '
    (.plugins // []) |= map(select((. | gsub("[./]"; "-")) != env.FILTER_SLUG))
  ' "$LCT_CONFIG_FILE"
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
