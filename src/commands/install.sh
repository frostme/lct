module=${args[module]:-}
lctfile_path="$PWD/LCTFile"

if [[ -z "$module" && -f "$lctfile_path" ]]; then
  mapfile -t MODULES < <(
    sed -e 's/#.*$//' "$lctfile_path" | awk 'NF'
  )

  if [[ ${#MODULES[@]} -eq 0 ]]; then
    echo "❌ ERROR: No modules listed in ${lctfile_path}" >&2
    exit 1
  fi

  LCT_MODULES_DIR="$PWD/lct_modules"
  LCT_MODULES_BIN_DIR="$LCT_MODULES_DIR/bin"
  LCT_MODULES_CACHE_DIR="$PWD/.lct_cache/modules"

  module_installation
  exit $?
fi

ensure_config_defaults

if [[ -n "$module" ]]; then
  if [[ "$module" != */* && "$module" != /* && "$module" != .* && "$module" != file://* && "$module" != *://* ]]; then
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
