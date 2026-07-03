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

plugin_connect_timeout() {
  local timeout="${LCT_PLUGIN_CONNECT_TIMEOUT:-10}"
  if [[ ! "$timeout" =~ ^[0-9]+$ || "$timeout" -le 0 ]]; then
    timeout=10
  fi
  printf '%s\n' "$timeout"
}

plugin_network_timeout() {
  local timeout="${LCT_PLUGIN_NETWORK_TIMEOUT:-45}"
  if [[ ! "$timeout" =~ ^[0-9]+$ || "$timeout" -le 0 ]]; then
    timeout=45
  fi
  printf '%s\n' "$timeout"
}

plugin_git() {
  local ssh_command connect_timeout network_timeout
  connect_timeout="$(plugin_connect_timeout)"
  network_timeout="$(plugin_network_timeout)"
  ssh_command="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=${connect_timeout}}"

  env \
    GIT_TERMINAL_PROMPT=0 \
    GIT_ASKPASS=/bin/true \
    GCM_INTERACTIVE=Never \
    GIT_SSH_COMMAND="$ssh_command" \
    git \
    -c credential.interactive=never \
    -c core.askPass=/bin/true \
    -c http.lowSpeedLimit=1 \
    -c "http.lowSpeedTime=${network_timeout}" \
    -c "http.connectTimeout=${connect_timeout}" \
    "$@"
}

plugin_resolve_latest_ref() {
  local repo_dir="$1"
  local _ref_var="$2"
  local _version_var="$3"

  local latest_tag remote_ref next_ref next_version

  latest_tag="$(plugin_git -C "$repo_dir" tag --sort=-v:refname | head -n1)"
  if [[ -n "$latest_tag" ]]; then
    next_ref="$latest_tag"
    next_version="$latest_tag"
  else
    remote_ref="$(plugin_git -C "$repo_dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [[ -z "$remote_ref" ]]; then
      for candidate in origin/main origin/master HEAD; do
        if [[ "$candidate" == "HEAD" ]] || plugin_git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/$candidate"; then
          remote_ref="$candidate"
          break
        fi
      done
    fi

    next_ref="${remote_ref:-HEAD}"
    next_version="commit:$(plugin_git -C "$repo_dir" rev-parse --short "$next_ref" 2>/dev/null || echo unknown)"
  fi

  printf -v "$_ref_var" '%s' "$next_ref"
  printf -v "$_version_var" '%s' "$next_version"
}

plugin_resolve_requested_ref() {
  local repo_dir="$1"
  local requested_version="$2"
  local _ref_var="$3"
  local _version_var="$4"

  local next_ref next_version latest_ref_value latest_version_value

  if [[ -n "$requested_version" && "$requested_version" != "latest" ]]; then
    if ! plugin_git -C "$repo_dir" rev-parse --verify --quiet "${requested_version}^{commit}" >/dev/null; then
      return 1
    fi
    next_ref="$requested_version"
    next_version="$requested_version"
  else
    plugin_resolve_latest_ref "$repo_dir" latest_ref_value latest_version_value
    next_ref="$latest_ref_value"
    next_version="$latest_version_value"
  fi

  printf -v "$_ref_var" '%s' "$next_ref"
  printf -v "$_version_var" '%s' "$next_version"
}

plugin_export_tree() {
  local repo_dir="$1"
  local ref="$2"
  local subpath="$3"
  local dest_dir="$4"
  local tmpdir source_dir

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/lct-plugin-export.XXXXXX")" || return 1

  if [[ -n "$subpath" ]]; then
    if ! plugin_git -C "$repo_dir" cat-file -e "${ref}:${subpath}" 2>/dev/null; then
      rm -rf -- "$tmpdir"
      return 1
    fi

    if ! plugin_git -C "$repo_dir" archive "$ref" "$subpath" | tar -xf - -C "$tmpdir"; then
      rm -rf -- "$tmpdir"
      return 1
    fi
    source_dir="$tmpdir/$subpath"
  else
    if ! plugin_git -C "$repo_dir" archive "$ref" | tar -xf - -C "$tmpdir"; then
      rm -rf -- "$tmpdir"
      return 1
    fi
    source_dir="$tmpdir"
  fi

  if [[ ! -d "$source_dir" ]]; then
    rm -rf -- "$tmpdir"
    return 1
  fi

  rm -rf -- "$dest_dir"
  mkdir -p "$dest_dir"
  (
    shopt -s dotglob nullglob
    cp -R "$source_dir"/. "$dest_dir"/
  )
  rm -rf -- "$tmpdir"
}

plugin_installation() {
  : "${LCT_PLUGINS_DIR:?LCT_PLUGINS_DIR is required}"

  if [[ ! -f "${LCT_CONFIG_FILE}" ]]; then
    echo "❌ ERROR: config.yaml file not found at ${LCT_CONFIG_FILE}" >&2
    exit 1
  fi

  if [[ ${#PLUGINS[@]} -eq 0 ]]; then
    lct_log_debug "plugin_installation found no plugins to install"
    echo "No plugins specified in config.yaml, nothing to install." >&2
    return 0
  fi

  gum_title "Starting plugin installation..."
  lct_log_debug "plugin_installation started (plugins=${#PLUGINS[@]})"

  local force_refresh="${PLUGIN_INSTALL_FORCE:-0}"
  local plugin plugin_name requested_version repo_url plugin_cache_root plugin_cache_meta
  local plugin_dest plugin_meta_file plugin_subpath cache_commit resolved_ref resolved_version
  local resolved_commit installed_commit install_needed pinned status_label migrated_commit migrated_subpath

  for plugin in "${PLUGINS[@]}"; do
    plugin_parse_entry "$plugin" plugin_name requested_version
    lct_log_debug "Processing plugin entry: ${plugin_name} (requested_version=${requested_version:-latest})"

    if ! plugin_ref_is_valid "$plugin_name"; then
      echo "❌ ERROR: Invalid plugin identifier '${plugin_name}'" >&2
      exit 1
    fi

    repo_url="$(plugin_repo_url "$plugin_name")"
    plugin_cache_root="$(plugin_cache_root "$plugin_name")"
    plugin_cache_meta="${plugin_cache_root}/.lct-cache"
    plugin_dest="$(plugin_install_dir "$plugin_name")"
    plugin_meta_file="$(plugin_installed_metadata_file "$plugin_name")"
    plugin_subpath="$(plugin_subpath_for_name "$plugin_name")"
    pinned=0
    [[ -n "$requested_version" && "$requested_version" != "latest" ]] && pinned=1

    if [[ "$force_refresh" -eq 1 && -d "$plugin_cache_root" ]]; then
      rm -rf -- "$plugin_cache_root"
    fi

    if [[ ! -d "$plugin_cache_root/.git" ]]; then
      [[ -d "$plugin_cache_root" ]] && rm -rf -- "$plugin_cache_root"
      mkdir -p "$(dirname "$plugin_cache_root")"
      gum_spinner "Cloning $(basename "$plugin_cache_root")" plugin_git clone "$repo_url" "$plugin_cache_root" >/dev/null 2>&1 ||
        {
          echo "❌ ERROR: Unable to clone repository $repo_url" >&2
          exit 1
        }
    fi

    if ! plugin_git -C "$plugin_cache_root" fetch --quiet --tags; then
      echo "❌ WARNING: Unable to refresh cached plugin $plugin_name" >&2
    fi

    if ! plugin_resolve_requested_ref "$plugin_cache_root" "$requested_version" resolved_ref resolved_version; then
      echo "❌ ERROR: Unable to find version '${requested_version}' for plugin ${plugin_name}" >&2
      exit 1
    fi

    resolved_commit="$(plugin_git -C "$plugin_cache_root" rev-parse "$resolved_ref" 2>/dev/null || true)"
    cache_commit="$(plugin_git -C "$plugin_cache_root" rev-parse HEAD 2>/dev/null || true)"
    installed_commit="$(plugin_metadata_get "installed_commit" "$plugin_meta_file")"
    migrated_commit=""
    migrated_subpath=""

    if [[ -z "$installed_commit" ]]; then
      migrated_commit="$(cache_metadata_get "installed_commit" "$plugin_cache_meta")"
      migrated_subpath="$(cache_metadata_get "subpath" "$plugin_cache_meta")"
      if [[ "$migrated_subpath" != "$plugin_subpath" ]]; then
        migrated_commit=""
      fi
      [[ -n "$migrated_commit" ]] && installed_commit="$migrated_commit"
    fi

    install_needed=0
    status_label="Loaded"
    if [[ "$force_refresh" -eq 1 ]]; then
      install_needed=1
    elif [[ ! -d "$plugin_dest" ]]; then
      install_needed=1
    elif [[ -z "$installed_commit" || "$installed_commit" != "$resolved_commit" ]]; then
      install_needed=1
    fi

    if [[ $install_needed -eq 1 ]]; then
      if ! plugin_export_tree "$plugin_cache_root" "$resolved_ref" "$plugin_subpath" "$plugin_dest"; then
        if [[ -n "$plugin_subpath" ]]; then
          echo "❌ ERROR: Plugin directory ${plugin_subpath} not found in ${repo_url} at ${resolved_ref}" >&2
        else
          echo "❌ ERROR: Unable to export plugin ${plugin_name} at ${resolved_ref}" >&2
        fi
        exit 1
      fi
      status_label="Installed"
    fi

    plugin_metadata_write \
      "$plugin_meta_file" \
      "$plugin_name" \
      "$repo_url" \
      "$resolved_version" \
      "$requested_version" \
      "$resolved_commit" \
      "$resolved_ref" \
      "$plugin_subpath" \
      "$pinned"

    cache_metadata_write "$plugin_cache_meta" "$repo_url" "$cache_commit" "$resolved_commit" "$plugin_subpath"

    echo "- ${status_label} plugin ${plugin_name}@${resolved_version}"
    if [[ "$pinned" -eq 1 ]]; then
      echo "  ↳ Pinned to ${requested_version}"
    fi
  done

  if gum_available; then
    gum style --foreground 121 "✅ Plugin installation complete"
  else
    echo "✅ Plugin installation complete"
  fi
  lct_log_info "plugin_installation completed"
}
