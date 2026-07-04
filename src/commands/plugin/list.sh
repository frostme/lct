mapfile -t plugins < <(installed_plugins | LC_ALL=C sort -f)

if [[ ${#plugins[@]} -eq 0 ]]; then
  echo "No plugins installed."
  exit 0
fi

plugin_list_entries=()

for plugin_slug in "${plugins[@]}"; do
  plugin_dir="$LCT_PLUGINS_DIR/$plugin_slug"
  meta_file="$plugin_dir/.lct-plugin"
  plugin_name="$(plugin_metadata_get "plugin" "$meta_file")"
  installed_version="$(plugin_metadata_get "installed_version" "$meta_file")"
  pinned="$(plugin_metadata_get "pinned" "$meta_file")"

  if [[ -z "$plugin_name" ]]; then
    plugin_name="$plugin_slug"
  fi

  entry="$plugin_name"
  if [[ -n "$installed_version" ]]; then
    entry+="@${installed_version}"
  fi
  if [[ "$pinned" == "1" ]]; then
    entry+=" (pinned)"
  fi

  plugin_list_entries+=("$entry")
done

printf '%s\n' "${plugin_list_entries[@]}"
