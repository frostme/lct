module=${args[module]:-}
install_global=${args[--global]:-0}
lctfile_path="$PWD/LCTFile"

module_ref_is_valid() {
  local ref="$1"
  [[ "$ref" == */* || "$ref" == /* || "$ref" == .* || "$ref" == file://* || "$ref" == *://* ]]
}

lctfile_module_exists() {
  local lctfile="$1"
  local module_ref="$2"
  local module_slug
  module_slug="$(module_key_slug "$module_ref")"

  while IFS= read -r listed_module; do
    [[ -z "$listed_module" ]] && continue
    local parsed_name parsed_version
    module_parse_entry "$listed_module" parsed_name parsed_version
    if [[ "$(module_key_slug "$parsed_name")" == "$module_slug" ]]; then
      return 0
    fi
  done < <(sed -e 's/#.*$//' "$lctfile" | awk 'NF')

  return 1
}

lctfile_add_module_sorted() {
  local lctfile="$1"
  local module_ref="$2"

  mapfile -t entries < <(
    {
      sed -e 's/#.*$//' "$lctfile" | awk 'NF'
      printf '%s\n' "$module_ref"
    } | awk 'NF && !seen[$0]++' | sort
  )

  printf '%s\n' "${entries[@]}" >"$lctfile"
}

if [[ $install_global -eq 0 ]]; then
  if [[ ! -f "$lctfile_path" ]]; then
    echo "❌ ERROR: LCTFile not found at ${lctfile_path}" >&2
    exit 1
  fi

  if [[ -z "$module" ]]; then
    mapfile -t MODULES < <(sed -e 's/#.*$//' "$lctfile_path" | awk 'NF')

    if [[ ${#MODULES[@]} -eq 0 ]]; then
      echo "❌ ERROR: No modules listed in ${lctfile_path}" >&2
      exit 1
    fi
  else
    if ! module_ref_is_valid "$module"; then
      echo "❌ ERROR: Module must be in owner/repo format or point to a local/remote repository path" >&2
      exit 1
    fi

    MODULES=("$module")
  fi

  LCT_MODULES_DIR="$PWD/lct_modules"
  LCT_MODULES_BIN_DIR="$LCT_MODULES_DIR/bin"
  LCT_MODULES_CACHE_DIR="$PWD/.lct_cache/modules"

  module_installation || {
    echo "❌ ERROR: Module installation failed" >&2
    exit 1
  }

  if [[ -n "$module" ]] && ! lctfile_module_exists "$lctfile_path" "$module"; then
    lctfile_add_module_sorted "$lctfile_path" "$module"
  fi

  exit 0
fi

ensure_config_defaults

if [[ -n "$module" ]]; then
  if ! module_ref_is_valid "$module"; then
    echo "❌ ERROR: Module must be in owner/repo format or point to a local/remote repository path" >&2
    exit 1
  fi

  module_slug=$(module_key_slug "$module")
  module_exists=0

  while IFS= read -r configured_module; do
    [[ -z "$configured_module" ]] && continue
    if [[ "$(module_key_slug "$configured_module")" == "$module_slug" ]]; then
      module_exists=1
      break
    fi
  done < <(yq -r '.modules[]?' "$LCT_CONFIG_FILE" 2>/dev/null)

  if [[ $module_exists -eq 0 ]]; then
    append_unique "modules" "$module"
  fi

  MODULES=("$module")
fi

module_installation
