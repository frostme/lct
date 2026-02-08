dotfile_path=${args[file]}

if [[ "$dotfile_path" == "$HOME/"* ]]; then
  dotfile_path="${dotfile_path#$HOME/}"
fi

ensure_config_defaults
DOTFILE_PATH="$dotfile_path" yq -i '.dotfiles = (.dotfiles // []) | .dotfiles |= map(select(. != env(DOTFILE_PATH)))' "$LCT_CONFIG_FILE"
