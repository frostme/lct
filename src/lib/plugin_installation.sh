cache_metadata_get() {
  local key="$1"
  local file="$2"

  [[ -f "$file" ]] || return 0

  awk -F= -v k="$key" '$1 == k { sub($1 "=", ""); print; exit }' "$file"
}

cache_metadata_write() {
  local file="$1"
  local repo_url="$2"
  local cached_commit="$3"
  local installed_commit="$4"
  local subpath="$5"

  cat <<EOF >"$file"
repo_url=${repo_url}
cached_commit=${cached_commit}
installed_commit=${installed_commit}
subpath=${subpath}
updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

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
    plugin_cache_root="$LCT_PLUGINS_CACHE_DIR/$owner/$repo"
    plugin_cache_dest="$plugin_cache_root"
    plugin_dest="$LCT_PLUGINS_DIR/$owner-$repo${name:+-$name}"
    plugin_cache_meta="${plugin_cache_root}/.lct-cache"
    plugin_subpath=""

    # Clone repo if not already cloned into cache
    if [[ ! -d "$plugin_cache_root/.git" ]]; then
      if [[ -d "$plugin_cache_root" ]]; then
        rm -rf -- "$plugin_cache_root"
      fi
      gum_spinner "Cloning $repo" git clone "$repo_url" "$plugin_cache_root" >/dev/null 2>&1 ||
        {
          echo "❌ ERROR: Unable to clone repository $repo_url" >&2
          exit 1
        }
    fi

    if [[ -d "$plugin_cache_root/.git" ]]; then
      if ! git -C "$plugin_cache_root" fetch --quiet; then
        echo "❌ WARNING: Unable to refresh cached plugin $plugin" >&2
      fi

      remote_ref="$(git -C "$plugin_cache_root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
      if [[ -z "$remote_ref" ]]; then
        for candidate in origin/main origin/master; do
          if git -C "$plugin_cache_root" show-ref --verify --quiet "refs/remotes/$candidate"; then
            remote_ref="$candidate"
            break
          fi
        done
      fi

      if [[ -n "$remote_ref" ]]; then
        remote_commit="$(git -C "$plugin_cache_root" rev-parse "$remote_ref" 2>/dev/null || true)"
        cache_commit="$(git -C "$plugin_cache_root" rev-parse HEAD 2>/dev/null || true)"
        if [[ -n "$remote_commit" && "$remote_commit" != "$cache_commit" ]]; then
          git -C "$plugin_cache_root" reset --hard "$remote_ref" >/dev/null 2>&1 ||
            echo "❌ WARNING: Unable to fast-forward cached plugin $plugin" >&2
        fi
      fi
    fi

    if [[ -n "$name" ]]; then
      plugin_cache_dest="$plugin_cache_root/plugins/$name"
      plugin_subpath="plugins/$name"
    fi

    cache_commit="$(git -C "$plugin_cache_root" rev-parse HEAD 2>/dev/null || true)"
    installed_commit="$(cache_metadata_get "installed_commit" "$plugin_cache_meta")"
    install_needed=0
    if [[ ! -d "$plugin_dest" ]]; then
      install_needed=1
    elif [[ -n "$cache_commit" && "$installed_commit" != "$cache_commit" ]]; then
      install_needed=1
    fi

    if [[ $install_needed -eq 1 ]]; then
      if [[ -d $plugin_cache_dest ]]; then
        rm -rf -- "$plugin_dest"
        cp -r "$plugin_cache_dest" "$plugin_dest"
        cache_metadata_write "$plugin_cache_meta" "$repo_url" "$cache_commit" "$cache_commit" "$plugin_subpath"
        if [[ -d "$plugin_dest" ]]; then
          echo "- Installed plugin $plugin"
        else
          echo "❌ WARNING: Plugin $plugin could not be copied into $plugin_dest" >&2
        fi
      else
        echo "❌ WARNING: Plugin directory $name not found in $repo_url plugin repository" >&2
      fi
    else
      cache_metadata_write "$plugin_cache_meta" "$repo_url" "$cache_commit" "$installed_commit" "$plugin_subpath"
      if [[ -d $plugin_dest ]]; then
        echo "- Loaded plugin $plugin"
      fi
    fi

  done

  if gum_available; then
    gum style --foreground 121 "✅ Plugin installation complete"
  else
    echo "✅ Plugin installation complete"
  fi
}
