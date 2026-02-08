config_input=${args[config]}

if [[ ! -f "$LCT_CONFIG_FILE" ]]; then
  echo "❌ ERROR: config.yaml file not found at ${LCT_CONFIG_FILE}" >&2
  exit 1
fi

if [[ -z "$config_input" ]]; then
  echo "❌ ERROR: config is required" >&2
  exit 1
fi

if [[ "$config_input" == "$HOME/.config/"* ]]; then
  config_input="${config_input#"$HOME/.config/"}"
fi

config_input="${config_input%/}"

if [[ "$config_input" == */* ]]; then
  config_input="$(basename "$config_input")"
fi

if [[ -z "$config_input" ]]; then
  echo "❌ ERROR: config is required" >&2
  exit 1
fi

config_path="$HOME/.config/$config_input"
if [[ ! -d "$config_path" ]]; then
  echo "❌ ERROR: config directory not found at ${config_path}" >&2
  exit 1
fi

append_unique "configs" "$config_input"
echo "Added config ${config_input}"
