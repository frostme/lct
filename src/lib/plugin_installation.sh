plugin_installation() {
  # Directory to store plugins
  : "${LCT_PLUGINS_DIR:?LCT_PLUGINS_DIR is required}"

  # Parse plugins from configuration
  if [[ ! -f "${LCT_CONFIG_FILE}" ]]; then
    echo "❌ ERROR: config.yaml file not found at ${LCT_CONFIG_FILE}" >&2
    exit 1
  fi

  if [[ ${#PLUGINS[@]} -eq 0 ]]; then
    echo "No plugins specified in config.yaml, nothing to install." >&2
    exit 0
  fi

  gum_title "Starting plugin installation..."

  for idx in "${!PLUGINS[@]}"; do
    plugin="${PLUGINS[$idx]}"
    # Determine owner, repo, and name (if exists)
    owner="$(echo "$plugin" | awk -F '[/.]' '{print $1}')"
    repo="$(echo "$plugin" | awk -F '[/.]' '{print $2}')"
    name="$(echo "$plugin" | awk -F '.' '{print $2}')"

    repo_url="https://github.com/$owner/$repo.git"
    plugin_cache_dest="$LCT_PLUGINS_CACHE_DIR/$owner/$repo"
    plugin_dest="$LCT_PLUGINS_DIR/$owner-$repo${name:+-$name}"

    if [[ -d $plugin_dest ]]; then
      echo "- Loaded plugin $plugin"
    else
      # Clone repo if not already cloned into cache
      if [[ ! -d "$plugin_cache_dest" ]]; then
        gum_spinner "Cloning $repo" git clone "$repo_url" "$plugin_cache_dest" >/dev/null 2>&1 ||
          {
            echo "❌ ERROR: Unable to clone repository $repo_url" >&2
            exit 1
          }
      fi

      if [[ -n "$name" ]]; then
        plugin_cache_dest="$plugin_cache_dest/plugins/$name"
      fi

      if [[ -d $plugin_cache_dest ]]; then
        cp -r "$plugin_cache_dest" "$plugin_dest"

        echo "- Installed plugin $plugin"
      else
        echo "❌ WARNING: Plugin directory $name not found in $repo_url plugin repository" >&2
      fi
    fi

  done

  if gum_available; then
    gum style --foreground 121 "✅ Plugin installation complete"
  else
    echo "✅ Plugin installation complete"
  fi
}
