NON_INTERACTIVE=${args[--yes]:-0}

echo "Initializing lct configuration"
setup_directories

# Ensure expected files exist
[[ -f "${LCT_ALIAS_FILE}" ]] || touch "${LCT_ALIAS_FILE}"
[[ -f "${LCT_ENV_FILE}" ]] || touch "${LCT_ENV_FILE}"
[[ -f "${LCT_VERSIONS_FILE}" ]] || touch "${LCT_VERSIONS_FILE}"

# Seed config file with default structure
yq -i '
  .remote = (.remote // "") |
  .configs = (.configs // []) |
  .dotfiles = (.dotfiles // []) |
  .plugins = (.plugins // []) |
  .other = (.other // {})
' "${LCT_CONFIG_FILE}"

contains_item() {
  local needle="$1"
  shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# Remote repository prompt
current_remote=""
if [[ "${REMOTE_CONFIG_REPO:-null}" != "null" && -n "${REMOTE_CONFIG_REPO:-}" ]]; then
  current_remote="$REMOTE_CONFIG_REPO"
fi

if [[ $NON_INTERACTIVE -eq 0 ]]; then
  read -r -p "Remote repository for configs${current_remote:+ [$current_remote]}: " remote_input
  if [[ -n "$remote_input" ]]; then
    current_remote="$remote_input"
  fi
fi

yq -i ".remote = \"$current_remote\"" "${LCT_CONFIG_FILE}"

# Dotfile suggestions based on shell
shell_name=$(basename "${SHELL:-}")
suggested_dotfiles=()
case "$shell_name" in
  zsh) suggested_dotfiles=(".zshrc" ".zprofile") ;;
  bash) suggested_dotfiles=(".bashrc" ".bash_profile") ;;
esac

readarray -t current_dotfiles < <(yq -r '.dotfiles // [] | .[]' "${LCT_CONFIG_FILE}")

if [[ ${#suggested_dotfiles[@]} -gt 0 && $NON_INTERACTIVE -eq 0 ]]; then
  echo "Detected shell: ${shell_name:-unknown}"
  read -r -p "Add baseline dotfiles (${suggested_dotfiles[*]})? [y/N]: " add_dotfiles
  if [[ "$add_dotfiles" =~ ^[Yy]$ ]]; then
    for dotfile in "${suggested_dotfiles[@]}"; do
      if ! contains_item "$dotfile" "${current_dotfiles[@]}"; then
        yq -i ".dotfiles += [\"$dotfile\"]" "${LCT_CONFIG_FILE}"
        current_dotfiles+=("$dotfile")
      fi
    done
  fi
fi

if [[ $NON_INTERACTIVE -eq 0 ]]; then
  read -r -p "Additional dotfiles to track (space-separated, leave blank to skip): " extra_dotfiles
  if [[ -n "$extra_dotfiles" ]]; then
    for dotfile in $extra_dotfiles; do
      if ! contains_item "$dotfile" "${current_dotfiles[@]}"; then
        yq -i ".dotfiles += [\"$dotfile\"]" "${LCT_CONFIG_FILE}"
        current_dotfiles+=("$dotfile")
      fi
    done
  fi
fi

# Plugin suggestions
suggested_plugins=("zsh-users/zsh-autosuggestions" "zsh-users/zsh-syntax-highlighting")
readarray -t current_plugins < <(yq -r '.plugins // [] | .[]' "${LCT_CONFIG_FILE}")

if [[ $NON_INTERACTIVE -eq 0 ]]; then
  if [[ "$shell_name" != "zsh" ]]; then
    suggested_plugins=()
  fi

  if [[ ${#suggested_plugins[@]} -gt 0 ]]; then
    read -r -p "Add baseline plugins (${suggested_plugins[*]})? [y/N]: " add_plugins
    if [[ "$add_plugins" =~ ^[Yy]$ ]]; then
      for plugin in "${suggested_plugins[@]}"; do
        if ! contains_item "$plugin" "${current_plugins[@]}"; then
          yq -i ".plugins += [\"$plugin\"]" "${LCT_CONFIG_FILE}"
          current_plugins+=("$plugin")
        fi
      done
    fi
  fi

  read -r -p "Additional plugins to install (space-separated, leave blank to skip): " extra_plugins
  if [[ -n "$extra_plugins" ]]; then
    for plugin in $extra_plugins; do
      if ! contains_item "$plugin" "${current_plugins[@]}"; then
        yq -i ".plugins += [\"$plugin\"]" "${LCT_CONFIG_FILE}"
        current_plugins+=("$plugin")
      fi
    done
  fi
fi

# Ensure versions file has a latest key to avoid yq errors later
if ! yq '.latest' "${LCT_VERSIONS_FILE}" >/dev/null 2>&1; then
  echo 'latest: ""' > "${LCT_VERSIONS_FILE}"
fi

echo "lct init complete"
echo "initialized: $(date -Iseconds)" > "${LCT_INIT_STAMP}"
