plugin_parse_entry() {
  local spec="$1"
  local _name_var="$2"
  local _version_var="$3"

  local parsed_name parsed_version
  parsed_name="$spec"
  parsed_version=""

  if [[ "$spec" == *"="* ]]; then
    parsed_name="${spec%%=*}"
    parsed_version="${spec#*=}"
  fi

  parsed_name="${parsed_name#"${parsed_name%%[![:space:]]*}"}"
  parsed_name="${parsed_name%"${parsed_name##*[![:space:]]}"}"
  parsed_version="${parsed_version#"${parsed_version%%[![:space:]]*}"}"
  parsed_version="${parsed_version%"${parsed_version##*[![:space:]]}"}"
  parsed_version="${parsed_version%\"}"
  parsed_version="${parsed_version#\"}"
  parsed_version="${parsed_version%\'}"
  parsed_version="${parsed_version#\'}"

  printf -v "$_name_var" '%s' "$parsed_name"
  printf -v "$_version_var" '%s' "$parsed_version"
}

plugin_cli_ref_parse() {
  local ref="$1"
  local _name_var="$2"
  local _version_var="$3"

  local parsed_name parsed_version
  parsed_name="$ref"
  parsed_version=""

  if [[ "$ref" == *@* ]]; then
    parsed_name="${ref%@*}"
    parsed_version="${ref##*@}"
  fi

  printf -v "$_name_var" '%s' "$parsed_name"
  printf -v "$_version_var" '%s' "$parsed_version"
}

plugin_format_entry() {
  local name="$1"
  local version="$2"

  if [[ -n "$version" ]]; then
    printf "%s = '%s'\n" "$name" "$version"
  else
    printf '%s\n' "$name"
  fi
}

plugin_ref_is_valid() {
  local ref="$1"
  [[ "$ref" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+(\.[A-Za-z0-9._-]+)?$ ]]
}

plugin_repo_url() {
  local ref="$1"
  local base

  base="${LCT_GITHUB_BASE:-https://github.com}"
  base="${base%/}"
  printf '%s/%s\n' "$base" "${ref%%.*}"
}

plugin_cache_root() {
  local name="$1"
  local owner repo

  owner="${name%%/*}"
  repo="${name#*/}"
  repo="${repo%%.*}"
  printf '%s/%s/%s\n' "$LCT_PLUGINS_CACHE_DIR" "$owner" "$repo"
}

plugin_installed_metadata_file() {
  local name="$1"
  local plugin_dir

  plugin_dir="$(plugin_install_dir "$name")"
  printf '%s/.lct-plugin\n' "$plugin_dir"
}

plugin_install_dir() {
  local name="$1"
  local owner repo plugin_name

  owner="${name%%/*}"
  repo="${name#*/}"
  plugin_name=""

  if [[ "$repo" == *.* ]]; then
    plugin_name="${repo#*.}"
    repo="${repo%%.*}"
  fi

  printf '%s/%s-%s%s\n' "$LCT_PLUGINS_DIR" "$owner" "$repo" "${plugin_name:+-$plugin_name}"
}

plugin_subpath_for_name() {
  local name="$1"
  local repo

  repo="${name#*/}"
  if [[ "$repo" == *.* ]]; then
    printf 'plugins/%s\n' "${repo#*.}"
  else
    printf '\n'
  fi
}

plugin_metadata_get() {
  local key="$1"
  local file="$2"

  [[ -f "$file" ]] || return 0
  awk -F= -v k="$key" '$1 == k { sub($1 "=", ""); print; exit }' "$file"
}

plugin_metadata_write() {
  local file="$1"
  local plugin_name="$2"
  local repo_url="$3"
  local installed_version="$4"
  local requested_version="$5"
  local installed_commit="$6"
  local source_ref="$7"
  local subpath="$8"
  local pinned="$9"

  cat <<EOF >"$file"
plugin=${plugin_name}
repo_url=${repo_url}
installed_version=${installed_version}
requested_version=${requested_version}
installed_commit=${installed_commit}
source_ref=${source_ref}
subpath=${subpath}
pinned=${pinned}
updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

cached_plugins() {
  [ -d "$LCT_PLUGINS_CACHE_DIR" ] || return 0

  find "$LCT_PLUGINS_CACHE_DIR" \
    -mindepth 2 -maxdepth 2 \
    -type d \
    -print |
    while IFS= read -r plugin_dir; do
      owner="$(basename "$(dirname "$plugin_dir")")"
      plugin="$(basename "$plugin_dir")"

      printf '%s-%s\n' "$owner" "$plugin"

      sub_root="$plugin_dir/plugins"
      if [ -d "$sub_root" ]; then
        find "$sub_root" \
          -mindepth 1 -maxdepth 1 \
          -type d \
          -name '.*' -prune -o \
          -type d \
          -print |
          while IFS= read -r sub_dir; do
            sub="$(basename "$sub_dir")"
            printf '%s-%s-%s\n' "$owner" "$plugin" "$sub"
          done
      fi
    done
}

installed_plugins() {
  [ -d "$LCT_PLUGINS_DIR" ] || return 0

  find "$LCT_PLUGINS_DIR" \
    -mindepth 1 -maxdepth 1 \
    -type d \
    -print |
    while IFS= read -r d; do
      plugin="$(basename "$d")"
      printf '%s\n' "$plugin"
    done
}

plugin_key_slug() {
  # input: owner/repo or owner/repo.name
  # output: owner-repo or owner-repo-name
  local s
  plugin_parse_entry "$1" s _
  s="${s//\//-}"
  s="${s//./-}"
  printf '%s\n' "$s"
}

plugin_paths_for_entry() {
  local root="$1"  # e.g. ~/.cache/lct/plugins OR ~/.local/share/lct/plugins
  local entry="$2" # owner/repo or owner/repo.name

  local name owner repo subpath
  plugin_parse_entry "$entry" name _
  owner="${name%%/*}"
  repo="${name#*/}"
  subpath="$(plugin_subpath_for_name "$name")"
  repo="${repo%%.*}"

  if [[ -n "$subpath" ]]; then
    printf '%s/%s/%s/%s\n' "$root" "$owner" "$repo" "$subpath"
  else
    printf '%s/%s/%s\n' "$root" "$owner" "$repo"
  fi
}

load_plugins() {
  local plugin plugin_name plugin_dir main_script

  lct_log_debug "Loading plugin entrypoints (count=${#PLUGINS[@]})"
  for plugin in "${PLUGINS[@]}"; do
    plugin_parse_entry "$plugin" plugin_name _
    if ! plugin_ref_is_valid "$plugin_name"; then
      lct_log_error "Invalid plugin identifier: ${plugin}"
      echo "❌ ERROR: Invalid plugin identifier '${plugin}'. Expected only [A-Za-z0-9._-] characters with / separators." >&2
      return 1
    fi

    plugin_dir="$(plugin_install_dir "$plugin_name")"
    main_script="$plugin_dir/main.sh"

    if [[ -f "$main_script" ]]; then
      lct_log_debug "Sourcing plugin entrypoint ${main_script}"
      # shellcheck disable=SC1090
      source "$main_script"
    else
      lct_log_error "Plugin entrypoint not found: ${main_script}"
      echo "❌ ERROR: Plugin entrypoint not found at ${main_script}" >&2
      return 1
    fi
  done
}

rewrite_config_plugins() {
  local plugin_entries=("$@")
  yq -i '.plugins = []' "$LCT_CONFIG_FILE"
  for plugin_entry in "${plugin_entries[@]}"; do
    FIELD_VALUE="$plugin_entry" yq -i '.plugins += [env(FIELD_VALUE)]' "$LCT_CONFIG_FILE"
  done
}
