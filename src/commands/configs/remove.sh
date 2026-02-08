config_path=${args[config]}
config_name=$(basename "$config_path")

if [[ -z "$config_name" || "$config_name" == "." ]]; then
  echo "❌ ERROR: Config directory name is required" >&2
  exit 1
fi

ensure_config_defaults
CONFIG_NAME="$config_name" yq -i '.configs = (.configs // []) | .configs |= map(select(. != env(CONFIG_NAME)))' "$LCT_CONFIG_FILE"
