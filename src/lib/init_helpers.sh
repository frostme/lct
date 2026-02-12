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
other: {}
plugins: []
modules: []
EOF
  else
    yq -i '
      .remote = (.remote // null) |
      .configs = (.configs // []) |
      .dotfiles = (.dotfiles // []) |
      .other = (.other // {}) |
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
  if gum_confirm_prompt "Add baseline dotfiles (${suggestion_list})?"; then
    mapfile -t selected_dotfiles < <(gum_choose_multi "${suggestions[@]}")
    if [[ ${#selected_dotfiles[@]} -eq 0 ]]; then
      selected_dotfiles=("${suggestions[@]}")
    fi
    for dotfile in "${selected_dotfiles[@]}"; do
      append_unique "dotfiles" "$dotfile"
    done
  fi
}

run_init_flow() {
  gum_title "LCT initialization"
  ensure_init_paths
  ensure_config_defaults
  prompt_remote_repo
  prompt_dotfiles
  date >"$LCT_INIT_FILE"
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
    return
  fi

  echo "ℹ Running lct init to complete setup..."
  run_init_flow
}
