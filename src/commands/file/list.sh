ensure_config_defaults

mapfile -t file_mappings < <(yq -r '.other // {} | to_entries | .[]? | "\(.key)=\(.value)"' "$LCT_CONFIG_FILE")

if [[ ${#file_mappings[@]} -eq 0 ]]; then
  echo "No file mappings configured."
  exit 0
fi

printf '%s\n' "${file_mappings[@]}"
