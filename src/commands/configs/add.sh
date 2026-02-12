config_path=${args[config]}
config_name=$(basename "$config_path")

if [[ -z "$config_name" || "$config_name" == "." ]]; then
  echo "❌ ERROR: Config directory name is required" >&2
  exit 1
fi

ensure_config_defaults
append_unique "configs" "$config_name"
