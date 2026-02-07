ensure_init_paths() {
  mkdir -p "$LCT_CONFIG_DIR" "$LCT_SHARE_DIR" "$LCT_VERSIONS_DIR" "$LCT_CACHE_DIR" "$LCT_PLUGINS_CACHE_DIR"
  touch "$LCT_BREW_FILE" "$LCT_ENV_FILE" "$LCT_ALIAS_FILE" "$LCT_VERSIONS_FILE" "$LCT_CONFIG_FILE"
}

ensure_config_defaults() {
  if [[ ! -s "$LCT_CONFIG_FILE" ]]; then
    cat >"$LCT_CONFIG_FILE" <<'EOF'
remote: null
configs: []
dotfiles: []
other: {}
plugins: []
EOF
  else
    yq -i '
      .remote = (.remote // null) |
      .configs = (.configs // []) |
      .dotfiles = (.dotfiles // []) |
      .other = (.other // {}) |
      .plugins = (.plugins // [])
    ' "$LCT_CONFIG_FILE"
  fi
}

ensure_versions_file() {
  if [[ ! -s "$LCT_VERSIONS_FILE" ]]; then
    printf 'latest: ""\n' >"$LCT_VERSIONS_FILE"
  else
    yq -i '.latest = (.latest // "")' "$LCT_VERSIONS_FILE"
  fi
}

append_unique() {
  local field="$1"
  local value="$2"

  FIELD_VALUE="$value" yq -i ".${field} += [env.FIELD_VALUE] | .${field} |= unique" "$LCT_CONFIG_FILE"
}

prompt_remote_repo() {
  local current_remote
  current_remote=$(yq -r '.remote // ""' "$LCT_CONFIG_FILE")

  local prompt="Remote repository to store lct configurations"
  if [[ -n "$current_remote" ]]; then
    prompt+=" [$current_remote]"
  fi
  prompt+=": "

  read -r -p "$prompt" remote_value
  if [[ -z "$remote_value" ]]; then
    remote_value="$current_remote"
  fi

  if [[ -n "$remote_value" ]]; then
    REMOTE_VALUE="$remote_value" yq -i '.remote = env.REMOTE_VALUE' "$LCT_CONFIG_FILE"
  else
    yq -i '.remote = null' "$LCT_CONFIG_FILE"
  fi
}

prompt_dotfiles() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  local suggestions=()
  case "$shell_name" in
    zsh) suggestions+=(".zshrc") ;;
    bash) suggestions+=(".bashrc") ;;
  esac

  if [[ ${#suggestions[@]} -eq 0 ]]; then
    return
  fi

  local suggestion_list
  suggestion_list=$(printf '%s ' "${suggestions[@]}" | sed 's/[[:space:]]*$//')
  read -r -p "Add baseline dotfiles (${suggestion_list})? [y/N]: " add_dotfiles
  if [[ "$add_dotfiles" =~ ^[Yy]$ ]]; then
    for dotfile in "${suggestions[@]}"; do
      append_unique "dotfiles" "$dotfile"
    done
  fi
}

prompt_plugins() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  local suggestions=()
  case "$shell_name" in
    zsh)
      suggestions+=("zsh-users/zsh-autosuggestions")
      suggestions+=("zsh-users/zsh-syntax-highlighting")
      ;;
  esac

  if [[ ${#suggestions[@]} -eq 0 ]]; then
    read -r -p "Add any baseline plugins? (owner/repo[.name], comma separated, blank to skip): " plugin_input
    if [[ -z "$plugin_input" ]]; then
      return
    fi
    IFS=',' read -r -a suggestions <<<"$plugin_input"
  else
    local suggestion_list
    suggestion_list=$(printf '%s ' "${suggestions[@]}" | sed 's/[[:space:]]*$//')
    read -r -p "Add baseline plugins (${suggestion_list})? [y/N]: " add_plugins
    if [[ ! "$add_plugins" =~ ^[Yy]$ ]]; then
      return
    fi
  fi

  for plugin in "${suggestions[@]}"; do
    # trim whitespace
    plugin="${plugin#"${plugin%%[![:space:]]*}"}"
    plugin="${plugin%"${plugin##*[![:space:]]}"}"
    [[ -z "$plugin" ]] && continue
    append_unique "plugins" "$plugin"
  done
}

run_init_flow() {
  ensure_init_paths
  ensure_versions_file
  ensure_config_defaults
  prompt_remote_repo
  prompt_dotfiles
  prompt_plugins
  date >"$LCT_INIT_FILE"
  echo "✅ Initialization complete"
}

run_init_if_needed() {
  if [[ -f "$LCT_INIT_FILE" ]]; then
    return
  fi

  echo "ℹ Running lct init to complete setup..."
  run_init_flow
}
