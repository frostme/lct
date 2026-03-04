ensure_init_paths() {
  mkdir -p "$LCT_CONFIG_DIR" "$LCT_SHARE_DIR" "$LCT_REMOTE_DIR" "$LCT_CACHE_DIR" "$LCT_PLUGINS_CACHE_DIR" "$LCT_MODULES_DIR" "$LCT_MODULES_BIN_DIR" "$LCT_MODULES_CACHE_DIR"
  touch "$LCT_BREW_FILE" "$LCT_ENV_FILE" "$LCT_ALIAS_FILE" "$LCT_CONFIG_FILE"
}

ensure_config_defaults() {
  if [[ ! -s "$LCT_CONFIG_FILE" ]]; then
    cat >"$LCT_CONFIG_FILE" <<'EOF'
remote: null
configs: []
dotfiles: []
other: []
secrets: []
plugins: []
modules: []
EOF
  else
    yq -i '
      .remote = (.remote // null) |
      .configs = (.configs // []) |
      .dotfiles = (.dotfiles // []) |
      .other = ((.other // []) | to_entries | map(.value)) |
      .secrets = (.secrets // []) |
      .plugins = (.plugins // []) |
      .modules = (.modules // [])
    ' "$LCT_CONFIG_FILE"
  fi
}

append_unique() {
  local field="$1"
  local value="$2"

  if [[ -z "$value" ]]; then
    return
  fi

  FIELD_VALUE="$value" yq -i ".${field} += [env(FIELD_VALUE)] | .${field} |= unique" "$LCT_CONFIG_FILE"
}

prompt_remote_repo() {
  local current_remote
  current_remote=$(yq -r '.remote // ""' "$LCT_CONFIG_FILE")

  local prompt="Remote repository to store lct configurations"
  if [[ -n "$current_remote" ]]; then
    prompt+=" [$current_remote] (leave blank to keep)"
  fi
  prompt+=":"

  if gum_available; then
    remote_value=$(gum input --placeholder "$prompt" --value "$current_remote")
  else
    read -r -p "$prompt " remote_value
  fi
  if [[ -z "$remote_value" ]]; then
    remote_value="$current_remote"
  fi

  if [[ -n "$remote_value" ]]; then
    REMOTE_VALUE="$remote_value" yq -i '.remote = env(REMOTE_VALUE)' "$LCT_CONFIG_FILE"
  else
    yq -i '.remote = null' "$LCT_CONFIG_FILE"
  fi
}

clone_remote_repo_if_configured() {
  local remote_url
  remote_url=$(yq -r '.remote // ""' "$LCT_CONFIG_FILE")

  if [[ -z "$remote_url" || "$remote_url" == "null" ]]; then
    lct_log_debug "No remote configured; skipping remote clone"
    return 0
  fi

  lct_log_info "Cloning remote repository ${remote_url}"
  if ! git ls-remote "$remote_url" HEAD >/dev/null 2>&1; then
    echo "❌ Remote repository not found or inaccessible: $remote_url" >&2
    echo "Please ensure the remote exists, that you have network connectivity and access/credentials, then rerun lct init." >&2
    lct_log_error "Remote repository missing or inaccessible: ${remote_url}"
    return 1
  fi

  rm -rf "$LCT_REMOTE_DIR"
  mkdir -p "$LCT_REMOTE_DIR"

  if ! git clone "$remote_url" "$LCT_REMOTE_DIR" >/dev/null 2>&1; then
    echo "❌ Failed to clone remote repository: $remote_url" >&2
    lct_log_error "Failed to clone remote repository: ${remote_url}"
    return 1
  fi

  lct_log_debug "Remote repository cloned into ${LCT_REMOTE_DIR}"
}

seed_local_config_from_remote() {
  local imported=0
  local remote_config="$LCT_REMOTE_DIR/config.yaml"

  if [[ -f "$remote_config" ]]; then
    lct_log_info "Copying config.yaml from remote repository"
    cp "$remote_config" "$LCT_CONFIG_FILE"
    imported=1
  fi

  while IFS= read -r bundle_file; do
    [[ -n "$bundle_file" ]] || continue
    if [[ -f "$LCT_REMOTE_DIR/$bundle_file" ]]; then
      lct_log_info "Copying package bundle ${bundle_file} from remote repository"
      cp "$LCT_REMOTE_DIR/$bundle_file" "$LCT_SHARE_DIR/$bundle_file"
      imported=1
    fi
  done < <(_lct_package_bundle_known_files)

  if ((imported)); then
    lct_log_debug "Seeded local configuration from remote repository"
  fi
}

run_init_flow() {
  lct_log_debug "Running init flow"
  gum_title "LCT initialization"
  ensure_init_paths
  ensure_config_defaults
  prompt_remote_repo
  clone_remote_repo_if_configured
  seed_local_config_from_remote
  ensure_config_defaults
  load_configuration
  date >"$LCT_INIT_FILE"
  lct_log_info "Initialization completed and marker written to ${LCT_INIT_FILE}"
  if gum_available; then
    gum_join_vertical \
      "$(gum style --foreground 121 '✅ Initialization complete')" \
      "$(gum format --type code <"$LCT_CONFIG_FILE")"
  else
    echo "✅ Initialization complete"
  fi
}

run_init_if_needed() {
  if [[ -f "$LCT_INIT_FILE" ]]; then
    lct_log_debug "Initialization marker already present at ${LCT_INIT_FILE}"
    return
  fi

  lct_log_info "Initialization marker missing; running init flow"
  echo "ℹ Running lct init to complete setup..."
  run_init_flow
}
