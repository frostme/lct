list_global=${args[--global]:-0}
lctfile_path="$PWD/LCTFile"

if [[ $list_global -eq 0 ]]; then
  if [[ ! -f "$lctfile_path" ]]; then
    echo "❌ ERROR: LCTFile not found at ${lctfile_path}" >&2
    exit 1
  fi

  LCT_MODULES_DIR="$PWD/lct_modules"
  LCT_MODULES_BIN_DIR="$LCT_MODULES_DIR/bin"
  LCT_MODULES_CACHE_DIR="$PWD/.lct_cache/modules"
else
  ensure_config_defaults
fi

format_module_entry() {
  local slug="$1"
  local repo_url="$2"

  if [[ -n "$repo_url" ]]; then
    local cleaned="$repo_url"
    local is_local=0
    if [[ "$cleaned" == file://* || "$cleaned" == /* || "$cleaned" == .* ]]; then
      is_local=1
    fi
    cleaned="${cleaned#file://}"
    cleaned="${cleaned%.git}"
    cleaned="${cleaned%/}"
    if [[ $is_local -eq 1 ]]; then
      printf '%s\n' "$slug"
      return
    fi
    if [[ "$cleaned" =~ github.com/(.+)$ ]]; then
      cleaned="${BASH_REMATCH[1]}"
    elif [[ "$cleaned" =~ ^[^:]+://[^/]+/(.+)$ ]]; then
      cleaned="${BASH_REMATCH[1]}"
    fi
    printf '%s\n' "$cleaned"
  else
    printf '%s\n' "$slug"
  fi
}

module_entries=()

if [[ -d "$LCT_MODULES_DIR" ]]; then
  while IFS= read -r module_slug; do
    [[ -z "$module_slug" ]] && continue
    [[ "$module_slug" == "bin" ]] && continue

    meta_file="$LCT_MODULES_CACHE_DIR/$module_slug/.lct-cache"
    repo_url="$(cache_metadata_get "repo_url" "$meta_file")"
    module_entries+=("$(format_module_entry "$module_slug" "$repo_url")")
  done < <(find "$LCT_MODULES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -u)
fi

if [[ ${#module_entries[@]} -eq 0 ]]; then
  if [[ ${LCT_COMPLETIONS:-0} == 1 ]]; then
    exit 0
  fi

  if [[ $list_global -eq 1 ]]; then
    echo "No globally installed modules."
  else
    echo "No modules installed in this project."
  fi
  exit 0
fi

printf '%s\n' "${module_entries[@]}"
