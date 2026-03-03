remote_path=${args[file]}
if ! remote_path=$(to_home_tilde_path "$remote_path"); then
  echo "❌ ERROR: File path must resolve inside HOME" >&2
  exit 1
fi

ensure_config_defaults

if config_name="$(config_name_from_path "$remote_path" 0)"; then
  append_unique "configs" "$config_name"
  exit 0
fi

if is_home_dotfile_path "$remote_path"; then
  append_unique "dotfiles" "$remote_path"
  exit 0
fi

REMOTE_PATH="$remote_path" yq -i '.other = (.other // []) + [env(REMOTE_PATH)] | .other |= unique' "$LCT_CONFIG_FILE"
