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

if ! CONFIG_ENTRY="$config_input" yq -e '.configs // [] | index(env.CONFIG_ENTRY)' "$LCT_CONFIG_FILE" >/dev/null 2>&1; then
  echo "❌ ERROR: config '${config_input}' not found in config." >&2
  exit 1
fi

CONFIG_ENTRY="$config_input" yq -i '(.configs // []) |= map(select(. != env.CONFIG_ENTRY))' "$LCT_CONFIG_FILE"
echo "Removed config ${config_input}"
