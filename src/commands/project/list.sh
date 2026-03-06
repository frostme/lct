ensure_config_defaults

mapfile -t projects < <(yq -r '.projects // [] | .[]' "$LCT_CONFIG_FILE" 2>/dev/null | awk 'NF' | LC_ALL=C sort -f)

if [[ ${#projects[@]} -eq 0 ]]; then
  echo "No projects configured."
  exit 0
fi

printf '%s\n' "${projects[@]}"
