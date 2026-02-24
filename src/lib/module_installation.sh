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

module_owner_repo() {
  local ref="$1"
  if [[ "$ref" == */* && "$ref" != /* && "$ref" != .* && "$ref" != file://* && "$ref" != *"://"* ]]; then
    printf '%s\n' "$ref"
    return 0
  fi
  return 1
}

module_release_api_base() {
  local base="${LCT_GITHUB_API_BASE:-}"
  if [[ -z "$base" ]]; then
    if [[ -n "${LCT_GITHUB_BASE:-}" && "$LCT_GITHUB_BASE" != file://* ]]; then
      base="${LCT_GITHUB_BASE%/}/api/v3"
    else
      base="https://api.github.com"
    fi
  fi

  printf '%s\n' "${base%/}"
}

module_download_release() {
  local owner_repo="$1"
  local tag="$2"
  local target_dir="$3"
  local _tag_var="$4"

  local api_base release_url response tarball_url release_tag tmpdir extracted_dir

  api_base="$(module_release_api_base)"
  release_url="${api_base}/repos/${owner_repo}/releases"
  if [[ -n "$tag" && "$tag" != "latest" ]]; then
    release_url+="/tags/${tag}"
  else
    release_url+="/latest"
  fi

  response="$(curl -fsSL "$release_url" 2>/dev/null)" || return 1

  tarball_url="$(python - "$response" -c 'import json,sys;data=json.loads(sys.argv[1] or "{}");print(data.get("tarball_url") or data.get("zipball_url") or "")' 2>/dev/null)"
  release_tag="$(python - "$response" -c 'import json,sys;data=json.loads(sys.argv[1] or "{}");print(data.get("tag_name") or "")' 2>/dev/null)"

  [[ -n "$tarball_url" ]] || return 1

  tmpdir="$(mktemp -d)"
  if ! curl -fsSL "$tarball_url" -o "$tmpdir/release.tar.gz" 2>/dev/null; then
    rm -rf -- "$tmpdir"
    return 1
  fi

  mkdir -p "$target_dir"
  if ! tar -xzf "$tmpdir/release.tar.gz" -C "$tmpdir" 2>/dev/null; then
    rm -rf -- "$tmpdir"
    return 1
  fi

  extracted_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  [[ -d "$extracted_dir" ]] || {
    rm -rf -- "$tmpdir"
    return 1
  }

  rm -rf -- "$target_dir"
  mkdir -p "$target_dir"
  (
    shopt -s dotglob nullglob
    cp -R "$extracted_dir"/. "$target_dir"/
  )
  rm -rf "$target_dir/.git"
  printf -v "$_tag_var" '%s' "$release_tag"
  rm -rf -- "$tmpdir"
  return 0
}

module_select_manager() {
  local candidates=("$@")
  local candidate

  for candidate in "${candidates[@]}"; do
    [[ -z "$candidate" ]] && continue
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf '%s\n' "${candidates[0]}"
}

module_extract_json_field() {
  local file="$1"
  local key="$2"
  local default_value="${3:-}"

  [[ -f "$file" ]] || {
    printf '%s\n' "$default_value"
    return
  }

  python - "$file" "$key" "$default_value" <<'PY' 2>/dev/null || printf '%s\n' "$default_value"
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
default = sys.argv[3] if len(sys.argv) > 3 else ""
try:
    data = json.loads(path.read_text())
    value = data
    for part in key.split("."):
        if isinstance(value, dict):
            value = value.get(part)
        else:
            value = None
            break
    if value is None:
        print(default)
    else:
        print(value)
except Exception:
    print(default)
PY
}

module_extract_toml_value() {
  local file="$1"
  local dotted_key="$2"
  local default_value="${3:-}"

  [[ -f "$file" ]] || {
    printf '%s\n' "$default_value"
    return
  }

  python - "$file" "$dotted_key" "$default_value" <<'PY' 2>/dev/null || printf '%s\n' "$default_value"
import sys, re
from pathlib import Path

path = Path(sys.argv[1])
key_parts = sys.argv[2].split(".")
default = sys.argv[3] if len(sys.argv) > 3 else ""
data = path.read_text()

def parse_with_tomllib():
    try:
        import tomllib
    except Exception:
        return None
    try:
        parsed = tomllib.loads(data)
    except Exception:
        return None
    value = parsed
    for part in key_parts:
        if isinstance(value, dict):
            value = value.get(part)
        else:
            return None
    return value

value = parse_with_tomllib()
if value is None:
    # Simple fallback: search for `<key> = "<value>"` under the top-level section
    pattern = rf'^\s*{re.escape(key_parts[-1])}\s*=\s*["\\\']([^"\\\']+)'
    match = re.search(pattern, data, flags=re.MULTILINE)
    if match:
        value = match.group(1)

print(value if value is not None else default)
PY
}

module_extract_xml_value() {
  local file="$1"
  local xpath="$2"
  local default_value="${3:-}"

  [[ -f "$file" ]] || {
    printf '%s\n' "$default_value"
    return
  }

  python - "$file" "$xpath" "$default_value" <<'PY' 2>/dev/null || printf '%s\n' "$default_value"
import sys, xml.etree.ElementTree as ET
from pathlib import Path

path = Path(sys.argv[1])
xpath = sys.argv[2].split("/")
default = sys.argv[3] if len(sys.argv) > 3 else ""

try:
    tree = ET.parse(path)
    node = tree.getroot()
    for part in xpath:
        if not part:
            continue
        node = node.find(part)
        if node is None:
            print(default)
            sys.exit(0)
    if node is None or node.text is None:
        print(default)
    else:
        print(node.text.strip())
except Exception:
    print(default)
PY
}

module_detect_install_strategy() {
  local dir="$1"
  local module_name="$2"

  if [[ -f "$dir/package.json" ]]; then
    local package manager
    package="$(module_extract_json_field "$dir/package.json" "name" "$(module_repo_name "$module_name")")"
    manager="$(module_select_manager pnpm npm yarn bun)"
    printf 'package_manager|%s|%s\n' "$manager" "$package"
    return
  fi

  if [[ -f "$dir/Cargo.toml" ]]; then
    local package manager
    package="$(module_extract_toml_value "$dir/Cargo.toml" "package.name" "$(module_repo_name "$module_name")")"
    manager="$(module_select_manager cargo-binstall cargo)"
    printf 'package_manager|%s|%s\n' "$manager" "$package"
    return
  fi

  if [[ -f "$dir/pyproject.toml" ]]; then
    local package manager
    package="$(module_extract_toml_value "$dir/pyproject.toml" "project.name" "")"
    [[ -n "$package" ]] || package="$(module_extract_toml_value "$dir/pyproject.toml" "tool.poetry.name" "$(module_repo_name "$module_name")")"
    manager="$(module_select_manager uv pip)"
    printf 'package_manager|%s|%s\n' "$manager" "$package"
    return
  fi

  if [[ -f "$dir/Gemfile" ]]; then
    local package
    package="$(grep -E "^[[:space:]]*gem ['\"]" "$dir/Gemfile" | head -n1 | sed -E "s/^[[:space:]]*gem ['\"]([^'\"]+).*/\\1/")"
    [[ -n "$package" ]] || package="$(module_repo_name "$module_name")"
    printf 'package_manager|gem|%s\n' "$package"
    return
  fi

  if [[ -f "$dir/go.mod" ]]; then
    local package manager
    package="$(grep -E '^module ' "$dir/go.mod" | head -n1 | awk '{print $2}')"
    [[ -n "$package" ]] || package="$(module_repo_url "$module_name")"
    manager="go"
    printf 'package_manager|%s|%s\n' "$manager" "$package"
    return
  fi

  if [[ -f "$dir/composer.json" ]]; then
    local package
    package="$(module_extract_json_field "$dir/composer.json" "name" "$(module_repo_name "$module_name")")"
    printf 'package_manager|composer|%s\n' "$package"
    return
  fi

  if [[ -f "$dir/pom.xml" ]]; then
    local artifact
    artifact="$(module_extract_xml_value "$dir/pom.xml" "artifactId" "$(module_repo_name "$module_name")")"
    printf 'builder|maven|%s\n' "$artifact"
    return
  fi

  if [[ -f "$dir/build.gradle" || -f "$dir/build.gradle.kts" ]]; then
    local project_name
    project_name="$(grep -E 'rootProject.name' "$dir"/build.gradle* 2>/dev/null | head -n1 | sed -E "s/.*=['\"]([^'\"]+).*/\\1/")"
    [[ -n "$project_name" ]] || project_name="$(module_repo_name "$module_name")"
    printf 'builder|gradle|%s\n' "$project_name"
    return
  fi

  if [[ -f "$dir"/*.csproj ]]; then
    local project_name
    project_name="$(module_extract_xml_value "$(ls "$dir"/*.csproj | head -n1)" "PropertyGroup/PackageId" "")"
    [[ -n "$project_name" ]] || project_name="$(module_extract_xml_value "$(ls "$dir"/*.csproj | head -n1)" "PropertyGroup/AssemblyName" "")"
    [[ -n "$project_name" ]] || project_name="$(module_repo_name "$module_name")"
    printf 'builder|dotnet|%s\n' "$project_name"
    return
  fi

  if [[ -f "$dir/Makefile" || -f "$dir/makefile" ]]; then
    printf 'make||\n'
    return
  fi

  printf 'default||\n'
}

module_run_make_steps() {
  local dir="$1"
  local prefix="$2"

  if [[ -x "$dir/configure" ]]; then
    (cd "$dir" && ./configure --prefix="$prefix") || (cd "$dir" && ./configure)
  fi

  if command -v make >/dev/null 2>&1; then
    (cd "$dir" && make -s) || (cd "$dir" && make)
    (cd "$dir" && make -s install PREFIX="$prefix" DESTDIR="$prefix") || true
  else
    echo "❌ ERROR: make is required to build this module" >&2
    return 1
  fi
}

module_run_builder() {
  local builder="$1"
  local dir="$2"

  case "$builder" in
  maven)
    (cd "$dir" && mvn -q package -DskipTests) || (cd "$dir" && mvn package -DskipTests)
    ;;
  gradle)
    (cd "$dir" && gradle installDist) || (cd "$dir" && ./gradlew installDist)
    ;;
  dotnet)
    if command -v dotnet >/dev/null 2>&1; then
      (cd "$dir" && dotnet restore)
      (cd "$dir" && dotnet publish -c Release -o "$dir/.lct-publish")
    else
      echo "❌ ERROR: dotnet is required to build this module" >&2
      return 1
    fi
    ;;
  esac
}

module_wrap_java_artifacts() {
  local dir="$1"
  local base="$2"

  local jar_path
  jar_path="$(find "$dir" -maxdepth 3 -type f -name '*.jar' | head -n1)"
  if [[ -n "$jar_path" ]]; then
    mkdir -p "$dir/bin"
    cat >"$dir/bin/$base" <<EOF
#!/usr/bin/env bash
exec java -jar "$(cd "$(dirname "$jar_path")" && pwd)/$(basename "$jar_path")" "\$@"
EOF
    chmod +x "$dir/bin/$base"
  fi

  local dll_path
  dll_path="$(find "$dir/.lct-publish" "$dir" -maxdepth 3 -type f \( -name '*.dll' -o -name '*.exe' \) 2>/dev/null | head -n1)"
  if [[ -n "$dll_path" ]]; then
    mkdir -p "$dir/bin"
    cat >"$dir/bin/$base" <<EOF
#!/usr/bin/env bash
exec dotnet "$(cd "$(dirname "$dll_path")" && pwd)/$(basename "$dll_path")" "\$@"
EOF
    chmod +x "$dir/bin/$base"
  fi
}

module_write_metadata() {
  local file="$1"
  local repo_url="$2"
  local cached_commit="$3"
  local installed_commit="$4"
  local strategy="$5"
  local manager="$6"
  local package="$7"

  cache_metadata_write "$file" "$repo_url" "$cached_commit" "$installed_commit" ""
  {
    echo "strategy=${strategy}"
    echo "manager=${manager}"
    echo "package=${package}"
  } >>"$file"
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
  local repo_url module_slug module_cache module_dest meta_file module_name owner_repo
  module_name="$module"

  repo_url=$(module_repo_url "$module_name") || {
    echo "❌ ERROR: Invalid module reference '${module_name}'. Expected owner/repo or path." >&2
    return 1
  }

  module_slug=$(module_key_slug "$module_name")
  module_cache="$LCT_MODULES_CACHE_DIR/$module_slug"
  module_dest="$LCT_MODULES_DIR/$module_slug"
  meta_file="$module_cache/.lct-cache"
  local status_label="Loaded"
  local cache_commit installed_commit install_needed=0 release_tag="" strategy strategy_detail strategy_name

  if [[ -z "$module_slug" ]]; then
    echo "❌ ERROR: Invalid module reference '${module}'" >&2
    return 1
  fi

  mkdir -p "$LCT_MODULES_CACHE_DIR"

  local release_attempted=0
  if owner_repo="$(module_owner_repo "$module_name")" && [[ "${LCT_GITHUB_BASE:-}" != file://* ]]; then
    if module_download_release "$owner_repo" "$version" "$module_cache" release_tag; then
      cache_commit="$release_tag"
      release_attempted=1
      [[ -n "$cache_commit" ]] || cache_commit="${version:-release}"
    fi
  fi

  if [[ $release_attempted -eq 0 ]]; then
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
  fi

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
    status_label="Installed"
  fi

  IFS='|' read -r strategy strategy_detail strategy_name <<<"$(module_detect_install_strategy "$module_dest" "$module_name")"
  if [[ $install_needed -eq 1 ]]; then
    case "$strategy" in
    package_manager)
      local manager package
      manager="$strategy_detail"
      package="$strategy_name"
      [[ -n "$package" ]] || package="$(module_repo_name "$module_name")"
      _lct_install_library "$manager" "$package" || return 1
      echo "  ↳ Installed via ${manager} (${package})"
      ;;
    make)
      module_run_make_steps "$module_dest" "$module_dest" || return 1
      ;;
    builder)
      module_run_builder "$strategy_detail" "$module_dest" || return 1
      module_wrap_java_artifacts "$module_dest" "${strategy_name:-$(module_repo_name "$module_name")}"
      ;;
    esac
  fi

  cache_commit="${cache_commit:-$(git -C "$module_cache" rev-parse HEAD 2>/dev/null || true)}"
  installed_commit="${cache_commit:-${installed_commit:-}}"
  module_write_metadata "$meta_file" "$repo_url" "$cache_commit" "$installed_commit" "$strategy" "$strategy_detail" "$strategy_name"

  echo "- ${status_label} module ${module_name}${version:+ @${version}}"

  if [[ "$strategy" != "package_manager" ]]; then
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
  local meta_file="$module_cache/.lct-cache"
  local strategy manager package
  strategy="$(cache_metadata_get "strategy" "$meta_file")"
  manager="$(cache_metadata_get "manager" "$meta_file")"
  package="$(cache_metadata_get "package" "$meta_file")"

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

  if [[ "$strategy" == "package_manager" && -n "$manager" && -n "$package" ]]; then
    _lct_remove_library "$manager" "$package" || {
      echo "❌ ERROR: Unable to remove package ${package} via ${manager}" >&2
      return 1
    }
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
