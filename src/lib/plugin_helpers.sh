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
  local s="$1"
  s="${s//\//-}"
  s="${s//./-}"
  printf '%s\n' "$s"
}

plugin_paths_for_entry() {
  local root="$1"  # e.g. ~/.cache/lct/plugins OR ~/.local/share/lct/plugins
  local entry="$2" # owner/repo or owner/repo.name

  local owner repo name
  owner="${entry%%/*}"
  repo="${entry#*/}"
  name=""

  if [[ "$repo" == *.* ]]; then
    name="${repo#*.}"
    repo="${repo%%.*}"
  fi

  if [[ -n "$name" ]]; then
    printf '%s/%s/%s/plugins/%s\n' "$root" "$owner" "$repo" "$name"
  else
    printf '%s/%s/%s\n' "$root" "$owner" "$repo"
  fi
}

load_plugins() {
  local plugin owner repo name plugin_dir main_script

  for plugin in "${PLUGINS[@]}"; do
    if [[ ! "$plugin" =~ ^[A-Za-z0-9._/-]+$ ]]; then
      echo "❌ ERROR: Invalid plugin identifier '${plugin}'. Expected only [A-Za-z0-9._-] characters with / separators." >&2
      return 1
    fi

    owner="${plugin%%/*}"
    repo="${plugin#*/}"
    name=""

    if [[ "$repo" == *.* ]]; then
      name="${repo#*.}"
      repo="${repo%%.*}"
    fi

    plugin_dir="$LCT_PLUGINS_DIR/$owner-$repo${name:+-$name}"
    main_script="$plugin_dir/main.sh"

    if [[ -f "$main_script" ]]; then
      # shellcheck disable=SC1090
      source "$main_script"
    else
      echo "❌ ERROR: Plugin entrypoint not found at ${main_script}" >&2
      return 1
    fi
  done
}
