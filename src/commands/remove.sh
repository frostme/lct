module=${args[module]:-}
remove_global=${args[--global]:-0}
lctfile_path="$PWD/LCTFile"

module_ref_is_valid() {
  local ref="$1"
  [[ "$ref" == */* || "$ref" == /* || "$ref" == .* || "$ref" == file://* || "$ref" == *://* ]]
}

lctfile_remove_module() {
  local lctfile="$1"
  local module_ref="$2"
  local module_slug
  module_slug="$(module_key_slug "$module_ref")"

  mapfile -t kept_entries < <(
    sed -e 's/#.*$//' "$lctfile" | awk 'NF' |
      while IFS= read -r listed_module; do
        [[ -z "$listed_module" ]] && continue
        local parsed_name parsed_version
        module_parse_entry "$listed_module" parsed_name parsed_version
        if [[ "$(module_key_slug "$parsed_name")" == "$module_slug" ]]; then
          continue
        fi
        printf '%s\n' "$listed_module"
      done
  )

  if [[ ${#kept_entries[@]} -eq 0 ]]; then
    : >"$lctfile"
  else
    printf '%s\n' "${kept_entries[@]}" >"$lctfile"
  fi
}

remove_global_module_from_config() {
  local module_ref="$1"
  local module_slug
  module_slug="$(module_key_slug "$module_ref")"

  mapfile -t configured_modules < <(yq -r '.modules[]?' "$LCT_CONFIG_FILE" 2>/dev/null)

  yq -i '.modules = []' "$LCT_CONFIG_FILE"

  for configured_module in "${configured_modules[@]}"; do
    [[ -z "$configured_module" ]] && continue

    local parsed_name parsed_version
    module_parse_entry "$configured_module" parsed_name parsed_version

    if [[ "$(module_key_slug "$parsed_name")" == "$module_slug" ]]; then
      continue
    fi

    append_unique "modules" "$configured_module"
  done
}

if [[ -z "$module" ]]; then
  echo "❌ ERROR: Module is required" >&2
  exit 1
fi

if ! module_ref_is_valid "$module"; then
  echo "❌ ERROR: Module must be in owner/repo format or point to a local/remote repository path" >&2
  exit 1
fi

if [[ $remove_global -eq 0 ]]; then
  LCT_MODULES_DIR="$PWD/lct_modules"
  LCT_MODULES_BIN_DIR="$LCT_MODULES_DIR/bin"
  LCT_MODULES_CACHE_DIR="$PWD/.lct_cache/modules"

  remove_module_repo "$module" || {
    echo "❌ ERROR: Module removal failed" >&2
    exit 1
  }

  if [[ -f "$lctfile_path" ]]; then
    lctfile_remove_module "$lctfile_path" "$module"
  fi

  exit 0
fi

ensure_config_defaults

remove_module_repo "$module" || {
  echo "❌ ERROR: Module removal failed" >&2
  exit 1
}

remove_global_module_from_config "$module"
