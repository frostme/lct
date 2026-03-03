remote_path=${args[file]}

if ! remote_path=$(to_home_tilde_path "$remote_path"); then
  echo "❌ ERROR: File destination must resolve inside HOME" >&2
  exit 1
fi

if [[ -z "$remote_path" || "$remote_path" == "~" ]]; then
  echo "❌ ERROR: File destination is required" >&2
  exit 1
fi

ensure_config_defaults

if config_name="$(config_name_from_path "$remote_path" 0)"; then
  CONFIG_NAME="$config_name" yq -i '.configs = (.configs // []) | .configs |= map(select(. != env(CONFIG_NAME)))' "$LCT_CONFIG_FILE"
  exit 0
fi

if is_home_dotfile_path "$remote_path"; then
  DOTFILE_PATH="$remote_path" yq -i '.dotfiles = (.dotfiles // []) | .dotfiles |= map(select(. != env(DOTFILE_PATH)))' "$LCT_CONFIG_FILE"
  exit 0
fi

REMOTE_PATH="$remote_path" yq -i '.other = (.other // []) | .other |= map(select(. != env(REMOTE_PATH)))' "$LCT_CONFIG_FILE"
