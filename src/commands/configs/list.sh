ensure_config_defaults

mapfile -t configs < <(yq -r '.configs // [] | .[]' "$LCT_CONFIG_FILE")

if [[ ${#configs[@]} -eq 0 ]]; then
  echo "No configs configured."
  exit 0
fi

printf '%s\n' "${configs[@]}"
