dotfile_path=${args[file]}

if [[ "$dotfile_path" == "$HOME/"* ]]; then
  dotfile_path="${dotfile_path#$HOME/}"
fi

ensure_config_defaults
append_unique "dotfiles" "$dotfile_path"
