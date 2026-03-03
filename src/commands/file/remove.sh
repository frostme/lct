remote_path=${args[file]}

if [[ "$remote_path" == "$HOME/"* ]]; then
  remote_path="${remote_path#"$HOME/"}"
fi

if [[ "$remote_path" == "~/"* ]]; then
  remote_path="${remote_path#~/}"
fi

if [[ -z "$remote_path" || "$remote_path" == "." ]]; then
  echo "❌ ERROR: File destination is required" >&2
  exit 1
fi

ensure_config_defaults
REMOTE_PATH="$remote_path" yq -i '.other = (.other // {}) | del(.other[env(REMOTE_PATH)])' "$LCT_CONFIG_FILE"
