ensure_config_defaults

file_mappings=()

mapfile -t configs < <(yq -r '.configs // [] | .[]' "$LCT_CONFIG_FILE")
for config_name in "${configs[@]}"; do
  [[ -n "$config_name" ]] || continue
  file_mappings+=("$(config_name_to_path "$config_name")")
done

mapfile -t dotfiles < <(yq -r '.dotfiles // [] | .[]' "$LCT_CONFIG_FILE")
file_mappings+=("${dotfiles[@]}")

mapfile -t other_files < <(yq -r '.other // [] | .[]' "$LCT_CONFIG_FILE")
file_mappings+=("${other_files[@]}")

if [[ ${#file_mappings[@]} -eq 0 ]]; then
  echo "No file mappings configured."
  exit 0
fi

mapfile -t file_mappings < <(printf '%s\n' "${file_mappings[@]}" | awk 'NF && !seen[$0]++')
printf '%s\n' "${file_mappings[@]}"
