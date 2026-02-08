if [[ ! -f "$LCT_CONFIG_FILE" ]]; then
  echo "❌ ERROR: config.yaml file not found at ${LCT_CONFIG_FILE}" >&2
  exit 1
fi

yq -r '.configs // [] | .[]' "$LCT_CONFIG_FILE"
