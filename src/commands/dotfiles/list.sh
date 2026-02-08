ensure_config_defaults

mapfile -t dotfiles < <(yq -r '.dotfiles // [] | .[]' "$LCT_CONFIG_FILE")

if [[ ${#dotfiles[@]} -eq 0 ]]; then
  echo "No dotfiles configured."
  exit 0
fi

printf '%s\n' "${dotfiles[@]}"
