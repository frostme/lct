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

LCT_MODULE_BIN_LINK_THRESHOLD="${LCT_MODULE_BIN_LINK_THRESHOLD:-100}"
LCT_MODULE_BIN_NO_CANDIDATE_SCORE="${LCT_MODULE_BIN_NO_CANDIDATE_SCORE:--10000}"

module_collect_candidates() {
  local dir="$1"
  local base="$2"
  local stem
  stem="${base%.*}"

  local explicit=(
    "$dir/bin/$base"
    "$dir/bin/$stem"
    "$dir/bin/${stem}.sh"
    "$dir/bin/${stem}.bash"
    "$dir/$base"
    "$dir/$stem"
    "$dir/${stem}.sh"
    "$dir/${stem}.bash"
    "$dir/main.sh"
    "$dir/run.sh"
    "$dir/start.sh"
    "$dir/Minifier.sh"
  )

  local candidate
  for candidate in "${explicit[@]}"; do
    [[ -f "$candidate" ]] && printf '%s\n' "$candidate"
  done

  find "$dir" -maxdepth 3 -type f \( -perm -111 -o -name '*.sh' -o -name '*.bash' \) 2>/dev/null
}

module_normalize_name() {
  local value="$1"
  value="${value%.sh}"
  value="${value%.bash}"
  printf '%s' "${value,,}" | tr -cd '[:alnum:]'
}

module_candidate_depth() {
  local dir="$1"
  local path="$2"
  local rel="${path#"$dir"/}"
  local slash_count
  slash_count=$(printf '%s' "$rel" | tr -cd '/' | wc -c | awk '{print $1}')
  printf '%s\n' "$((slash_count + 1))"
}

module_score_candidate() {
  local dir="$1"
  local path="$2"
  local base="$3"
  local stem="$4"

  local rel="${path#"$dir"/}"
  local name
  name="$(basename "$path")"
  local depth
  depth=$(module_candidate_depth "$dir" "$path")
  local normalized_name normalized_stem
  normalized_name=$(module_normalize_name "$name")
  normalized_stem=$(module_normalize_name "$stem")

  local score=0

  [[ "$rel" == bin/* ]] && ((score += 120))

  if [[ "$name" == "$base" || "$name" == "$stem" ]]; then
    ((score += 110))
  elif [[ "$name" == "${stem}.sh" || "$name" == "${stem}.bash" ]]; then
    ((score += 90))
  fi

  if [[ -n "$normalized_name" && -n "$normalized_stem" ]]; then
    if [[ "$normalized_name" == "$normalized_stem" ]]; then
      ((score += 90))
    elif [[ "$normalized_name" == *"$normalized_stem"* || "$normalized_stem" == *"$normalized_name"* ]]; then
      ((score += 60))
    fi

    local token
    local lower_stem
    lower_stem="${stem,,}"
    for token in ${lower_stem//[-_]/ }; do
      case "$token" in
      ""|bash|tool|module|script|cli)
        continue
        ;;
      esac

      if [[ "$normalized_name" == "$token" ]]; then
        ((score += 80))
      elif [[ "$normalized_name" == *"$token"* ]]; then
        ((score += 40))
      fi
    done
  fi

  [[ -x "$path" ]] && ((score += 40))

  if [[ "$depth" -eq 1 ]]; then
    ((score += 30))
  elif [[ "$depth" -eq 2 ]]; then
    ((score += 15))
  fi

  if head -n 1 "$path" 2>/dev/null | grep -q '^#!'; then
    ((score += 10))
  fi

  if [[ "$rel" =~ (^|/)(test|tests|spec|specs|docs|doc|example|examples|fixture|fixtures)/ ]]; then
    ((score -= 140))
  fi

  if [[ "$name" == *_test* || "$name" == *.test.* || "$name" == test_* ]]; then
    ((score -= 120))
  fi

  printf '%s\n' "$score"
}

module_find_main_script() {
  local dir="$1"
  local base="$2"
  local _path_var="$3"
  local _score_var="$4"
  local stem
  stem="${base%.*}"

  local best_path=""
  local best_score="$LCT_MODULE_BIN_NO_CANDIDATE_SCORE"
  local best_depth=999
  local candidate score depth

  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    score=$(module_score_candidate "$dir" "$candidate" "$base" "$stem")
    depth=$(module_candidate_depth "$dir" "$candidate")

    if (( score > best_score )); then
      best_path="$candidate"
      best_score="$score"
      best_depth="$depth"
      continue
    fi

    if (( score == best_score )) && (( depth < best_depth )); then
      best_path="$candidate"
      best_depth="$depth"
      continue
    fi

    if (( score == best_score )) && (( depth == best_depth )) && [[ -n "$best_path" && "$candidate" < "$best_path" ]]; then
      best_path="$candidate"
    fi
  done < <(module_collect_candidates "$dir" "$base" | sort -u)

  printf -v "$_score_var" '%s' "$best_score"

  if [[ -n "$best_path" && "$best_score" -ge "$LCT_MODULE_BIN_LINK_THRESHOLD" ]]; then
    printf -v "$_path_var" '%s' "$best_path"
  else
    printf -v "$_path_var" '%s' ""
  fi
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

  if [[ -z "$module_slug" ]]; then
    echo "❌ ERROR: Invalid module reference '${module}'" >&2
    return 1
  fi

  mkdir -p "$LCT_MODULES_CACHE_DIR"

  if [[ ! -d "$module_cache/.git" ]]; then
    [[ -d "$module_cache" ]] && rm -rf -- "$module_cache"
    mkdir -p "$(dirname "$module_cache")"
    if gum_available; then
      gum spin --spinner line --title "Cloning ${module}" -- git clone "$repo_url" "$module_cache" >/dev/null 2>&1 || {
        echo "❌ ERROR: Unable to clone module ${module}" >&2
        return 1
      }
    elif ! git clone "$repo_url" "$module_cache" >/dev/null 2>&1; then
      echo "❌ ERROR: Unable to clone module ${module}" >&2
      return 1
    fi
  fi

  if [[ -d "$module_cache/.git" ]]; then
    git -C "$module_cache" fetch --quiet --tags || echo "❌ WARNING: Unable to refresh module ${module}" >&2
  else
    echo "❌ ERROR: Missing module cache at ${module_cache}" >&2
    return 1
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

  local main_script main_script_score
  module_find_main_script "$module_dest" "$(module_repo_name "$module_name")" main_script main_script_score

  if [[ -n "$main_script" ]]; then
    chmod +x "$main_script"
    ln -sf "$main_script" "$LCT_MODULES_BIN_DIR/$(basename "$main_script")"
    echo "  ↳ Linked $(basename "$main_script")"
  elif [[ "$main_script_score" -gt "$LCT_MODULE_BIN_NO_CANDIDATE_SCORE" ]]; then
    echo "  ↳ Skipped bin link (low confidence)"
  else
    echo "  ↳ Skipped bin link (no runnable candidate)"
  fi
}


remove_module_repo() {
  local module="$1"
  local module_slug module_cache module_dest

  module_slug=$(module_key_slug "$module")
  if [[ -z "$module_slug" ]]; then
    echo "❌ ERROR: Invalid module reference '${module}'" >&2
    return 1
  fi

  module_cache="$LCT_MODULES_CACHE_DIR/$module_slug"
  module_dest="$LCT_MODULES_DIR/$module_slug"

  if [[ -d "$LCT_MODULES_BIN_DIR" ]]; then
    while IFS= read -r bin_entry; do
      [[ -L "$bin_entry" ]] || continue
      local target
      target="$(readlink "$bin_entry")"
      [[ "$target" != /* ]] && target="$(cd "$(dirname "$bin_entry")" && cd "$(dirname "$target")" && pwd)/$(basename "$target")"
      if [[ "$target" == "$module_dest"/* ]]; then
        rm -f -- "$bin_entry" || {
          echo "❌ ERROR: Unable to remove module link ${bin_entry}" >&2
          return 1
        }
      fi
    done < <(find "$LCT_MODULES_BIN_DIR" -mindepth 1 -maxdepth 1 -type l 2>/dev/null)
  fi

  if [[ -e "$module_dest" ]]; then
    rm -rf -- "$module_dest" || {
      echo "❌ ERROR: Unable to remove installed module ${module}" >&2
      return 1
    }
    echo "- Removed module ${module}"
  fi

  if [[ -e "$module_cache" ]]; then
    rm -rf -- "$module_cache" || {
      echo "❌ ERROR: Unable to prune module cache for ${module}" >&2
      return 1
    }
    echo "- Pruned module cache ${module}"
  fi

  return 0
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
