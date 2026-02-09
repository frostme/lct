module_parse_entry() {
  local spec="$1"
  local _name_var="$2"
  local _version_var="$3"

  local name version
  name="$spec"
  version=""

  if [[ "$spec" == *"="* ]]; then
    name="${spec%%=*}"
    version="${spec#*=}"
  fi

  # trim whitespace
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  version="${version#"${version%%[![:space:]]*}"}"
  version="${version%"${version##*[![:space:]]}"}"

  # strip surrounding quotes for version
  version="${version%\"}"
  version="${version#\"}"
  version="${version%\'}"
  version="${version#\'}"

  printf -v "$_name_var" '%s' "$name"
  printf -v "$_version_var" '%s' "$version"
}

module_repo_url() {
  local ref="$1"

  if [[ "$ref" == file://* ]]; then
    printf '%s\n' "${ref#file://}"
    return 0
  fi

  if [[ "$ref" == /* || "$ref" == .* ]]; then
    printf '%s\n' "$ref"
    return 0
  fi

  if [[ "$ref" == *://* ]]; then
    printf '%s\n' "$ref"
    return 0
  fi

  if [[ "$ref" == */* ]]; then
    local base
    base="${LCT_GITHUB_BASE:-https://github.com}"
    base="${base%/}"
    printf '%s/%s\n' "$base" "$ref"
    return 0
  fi

  return 1
}

module_repo_name() {
  local ref="$1"
  ref="${ref#file://}"
  if [[ "$ref" == *"="* ]]; then
    ref="${ref%%=*}"
  fi
  ref="${ref%/}"
  ref="$(basename "$ref")"
  ref="${ref%.git}"
  printf '%s\n' "$ref"
}

module_key_slug() {
  local ref="$1"
  if [[ "$ref" == */* && "$ref" != /* && "$ref" != file://* ]]; then
    ref="${ref//\//-}"
  else
    ref="$(module_repo_name "$ref")"
  fi
  ref="${ref//./-}"
  printf '%s\n' "$ref"
}

module_find_main_script() {
  local dir="$1"
  local base="$2"
  local stem
  stem="${base%.*}"

  shopt -s nullglob
  for candidate in \
    "$dir/bin/$base" \
    "$dir/bin/$stem" \
    "$dir/bin/${stem}.sh" \
    "$dir/bin/${stem}.bash" \
    "$dir/$base" \
    "$dir/$stem" \
    "$dir/${stem}.sh" \
    "$dir/${stem}.bash"; do
    if [[ -f "$candidate" ]]; then
      shopt -u nullglob
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  local executable
  executable=$(find "$dir" -maxdepth 2 -type f -perm -111 | head -n 1)
  if [[ -n "$executable" ]]; then
    shopt -u nullglob
    printf '%s\n' "$executable"
    return 0
  fi

  local script
  script=$(find "$dir" -maxdepth 2 -type f \( -name '*.sh' -o -name '*.bash' \) | head -n 1)
  shopt -u nullglob
  [[ -n "$script" ]] && printf '%s\n' "$script"
}

install_module_repo() {
  local module="$1"
  local version="$2"
  local repo_url module_slug module_cache module_dest meta_file module_name
  module_name="$module"

  repo_url=$(module_repo_url "$module_name") || {
    echo "❌ ERROR: Invalid module reference '${module_name}'. Expected owner/repo or path." >&2
    return 1
  }

  module_slug=$(module_key_slug "$module_name")
  module_cache="$LCT_MODULES_CACHE_DIR/$module_slug"
  module_dest="$LCT_MODULES_DIR/$module_slug"
  meta_file="$module_cache/.lct-cache"

  if [[ ! -d "$module_cache/.git" ]]; then
    [[ -d "$module_cache" ]] && rm -rf -- "$module_cache"
    if ! gum_spinner "Cloning ${module}" git clone "$repo_url" "$module_cache" >/dev/null 2>&1; then
      echo "❌ ERROR: Unable to clone module ${module}" >&2
      return 1
    fi
  else
    git -C "$module_cache" fetch --quiet --tags || echo "❌ WARNING: Unable to refresh module ${module}" >&2
  fi

  if [[ -n "$version" && "$version" != "latest" ]]; then
    if ! git -C "$module_cache" checkout --quiet "$version" 2>/dev/null; then
      echo "❌ ERROR: Unable to find version '${version}' for ${module_name}" >&2
      return 1
    fi
  else
    latest_ref="$(git -C "$module_cache" tag --sort=-v:refname | head -n1)"
    if [[ -n "$latest_ref" ]]; then
      git -C "$module_cache" checkout --quiet "$latest_ref" 2>/dev/null || true
    else
      remote_ref="$(git -C "$module_cache" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
      [[ -z "$remote_ref" ]] && remote_ref="HEAD"
      git -C "$module_cache" checkout --quiet "$remote_ref" 2>/dev/null || true
    fi
  fi

  cache_commit="$(git -C "$module_cache" rev-parse HEAD 2>/dev/null || true)"
  installed_commit="$(cache_metadata_get "installed_commit" "$meta_file")"

  install_needed=0
  if [[ ! -d "$module_dest" ]]; then
    install_needed=1
  elif [[ -n "$cache_commit" && "$installed_commit" != "$cache_commit" ]]; then
    install_needed=1
  fi

  if [[ $install_needed -eq 1 ]]; then
    rm -rf -- "$module_dest"
    mkdir -p "$module_dest"
    (
      shopt -s dotglob nullglob
      cp -R "$module_cache"/. "$module_dest"/
    )
    rm -rf "$module_dest/.git"
    cache_metadata_write "$meta_file" "$repo_url" "$cache_commit" "$cache_commit" ""
    echo "- Installed module ${module_name}${version:+ @${version}}"
  else
    cache_metadata_write "$meta_file" "$repo_url" "$cache_commit" "$installed_commit" ""
    [[ -d "$module_dest" ]] && echo "- Loaded module ${module_name}${version:+ @${version}}"
  fi

  main_script=$(module_find_main_script "$module_dest" "$(module_repo_name "$module_name")")
  if [[ -n "$main_script" ]]; then
    chmod +x "$main_script"
    ln -sf "$main_script" "$LCT_MODULES_BIN_DIR/$(basename "$main_script")"
    echo "  ↳ Linked $(basename "$main_script")"
  else
    echo "❌ WARNING: No runnable script found for ${module}" >&2
  fi
}

module_installation() {
  : "${LCT_MODULES_DIR:?LCT_MODULES_DIR is required}"
  : "${LCT_MODULES_BIN_DIR:?LCT_MODULES_BIN_DIR is required}"
  : "${LCT_MODULES_CACHE_DIR:?LCT_MODULES_CACHE_DIR is required}"

  mkdir -p "$LCT_MODULES_DIR" "$LCT_MODULES_BIN_DIR" "$LCT_MODULES_CACHE_DIR"

  if [[ ${#MODULES[@]} -eq 0 ]]; then
    echo "No modules specified in config.yaml, nothing to install." >&2
    return 0
  fi

  gum_title "Starting module installation..."

  local failures=0
  for module in "${MODULES[@]}"; do
    local parsed_name parsed_version
    module_parse_entry "$module" parsed_name parsed_version
    install_module_repo "$parsed_name" "$parsed_version" || failures=1
  done

  if gum_available; then
    gum style --foreground 121 "✅ Module installation complete"
  else
    echo "✅ Module installation complete"
  fi

  return $failures
}
