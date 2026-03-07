ensure_config_defaults

mapfile -t secrets < <(yq -r '.secrets // [] | .[]' "$LCT_CONFIG_FILE")

if [[ ${#secrets[@]} -eq 0 ]]; then
  echo "No secrets configured."
  exit 0
fi

mapfile -t secrets < <(printf '%s\n' "${secrets[@]}" | awk 'NF && !seen[$0]++')
printf '%s\n' "${secrets[@]}"
