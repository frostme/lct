enable_stacktrace
enable_auto_colors

LCT_PACKAGE_MANAGER=""

# -----------------------------
# Function: set_origin_remote
# Description:
#   - Configures the origin remote of the git repository in LCT_VERSIONS_DIR to match REMOTE_CONFIG_REPO.
# Preconditions:
#   - REMOTE_CONFIG_REPO: Git URL (e.g., https://github.com/org/repo.git or git@github.com:org/repo.git).
#   - LCT_VERSIONS_DIR: Path to a git working tree.
# -----------------------------
set_origin_remote() {
  # Validate required environment variables
  : "${REMOTE_CONFIG_REPO:?REMOTE_CONFIG_REPO is required}"
  : "${LCT_VERSIONS_DIR:?LCT_VERSIONS_DIR is required}"

  # Check if LCT_VERSIONS_DIR is a valid git repository
  if [[ ! -d "$LCT_VERSIONS_DIR/.git" ]]; then
    echo "Error: Not a git repo: $LCT_VERSIONS_DIR" >&2
    return 1
  fi

  local current

  # Get current remote URL, if it exists
  current="$(git -C "$LCT_VERSIONS_DIR" remote get-url origin 2>/dev/null || true)"

  # Update or set the remote as needed
  if [[ -z "$current" ]]; then
    git -C "$LCT_VERSIONS_DIR" remote add origin "$REMOTE_CONFIG_REPO" &>/dev/null
  elif [[ "$current" != "$REMOTE_CONFIG_REPO" ]]; then
    git -C "$LCT_VERSIONS_DIR" remote set-url origin "$REMOTE_CONFIG_REPO" &>/dev/null
  fi
}

detect_directories() {
  if [ -z "${SOFTWARE_DIR+x}" ]; then
    SOFTWARE_DIR="$HOME/software"
  fi

  if [ -z "${CONFIG_DIR+x}" ]; then
    CONFIG_DIR="$HOME/.config"
  fi

  if [ -z "${SHARE_DIR+x}" ]; then
    SHARE_DIR="$HOME/.local/share"
  fi

  if [ -z "${STATE_DIR+x}" ]; then
    STATE_DIR="$HOME/.local/state"
  fi

  if [ -z "${CACHE_DIR+x}" ]; then
    CACHE_DIR="$HOME/.cache"
  fi

  LCT_SOFTWARE_DIR="${SOFTWARE_DIR}/lct"
  LCT_SHARE_DIR="${SHARE_DIR}/lct"
  LCT_CONFIG_DIR="${CONFIG_DIR}/lct"
  LCT_CACHE_DIR="${CACHE_DIR}/lct"
  LCT_ENV_FILE="${LCT_SHARE_DIR}/env.yaml"
  LCT_CONFIG_FILE="${LCT_CONFIG_DIR}/config.yaml"
  LCT_VERSIONS_DIR="${LCT_SHARE_DIR}/config_versions"
  LCT_VERSIONS_FILE="${LCT_VERSIONS_DIR}/lct.yaml"
  LCT_BREW_FILE="${LCT_SHARE_DIR}/Brewfile"
  LCT_ALIAS_FILE="${LCT_SHARE_DIR}/alias.yaml"
  LCT_INIT_FILE="${LCT_SHARE_DIR}/.init_done"
  LCT_PLUGINS_CACHE_DIR="${LCT_CACHE_DIR}/plugins"
  LCT_PLUGINS_DIR="${LCT_SHARE_DIR}/plugins"
}

setup_directories() {
  detect_directories

  [[ -d "${LCT_SOFTWARE_DIR}" ]] || mkdir -p "${LCT_SOFTWARE_DIR}"
  [[ -d "${LCT_SHARE_DIR}" ]] || mkdir -p "${LCT_SHARE_DIR}"
  [[ -d "${LCT_CONFIG_DIR}" ]] || mkdir -p "${LCT_CONFIG_DIR}"
  [[ -d "${LCT_VERSIONS_DIR}" ]] || mkdir -p "${LCT_VERSIONS_DIR}"
  [[ -f "${LCT_ENV_FILE}" ]] || touch "${LCT_ENV_FILE}"
  [[ -f "${LCT_CONFIG_FILE}" ]] || touch "${LCT_CONFIG_FILE}"
  [[ -f "${LCT_ALIAS_FILE}" ]] || touch "${LCT_ALIAS_FILE}"
  [[ -f "${LCT_VERSIONS_FILE}" ]] || touch "${LCT_VERSIONS_FILE}"
  [[ -d "$LCT_VERSIONS_DIR/.git" ]] || git init -q -b main "$LCT_VERSIONS_DIR"
  [[ -f "${LCT_BREW_FILE}" ]] || touch "${LCT_BREW_FILE}"
  [[ -d "${LCT_CACHE_DIR}" ]] || mkdir -p "${LCT_CACHE_DIR}"
  [[ -d "${LCT_PLUGINS_DIR}" ]] || mkdir -p "${LCT_PLUGINS_DIR}"
  [[ -d "${LCT_PLUGINS_CACHE_DIR}" ]] || mkdir -p "${LCT_PLUGINS_CACHE_DIR}"
}

load_plugin_configs() {
  for plugin in "${PLUGINS[@]}"; do
    owner="$(echo "$plugin" | awk -F '[/.]' '{print $1}')"
    repo="$(echo "$plugin" | awk -F '[/.]' '{print $2}')"
    name="$(echo "$plugin" | awk -F '.' '{print $2}')"
    plugin_dir="$LCT_PLUGINS_DIR/$owner-$repo${name:+-$name}"
    plugin_cache_dir="$LCT_PLUGINS_CACHE_DIR/$owner/$repo"
    [[ -n "$name" ]] && plugin_cache_dir="$plugin_cache_dir/plugins/$name"

    plugin_config="$plugin_dir/config.yaml"
    [[ -f "$plugin_config" ]] || plugin_config="$plugin_cache_dir/config.yaml"
    [[ -f "$plugin_config" ]] || continue

    mapfile -t plugin_configs < <(yq -r '.configs // [] | .[]' "$plugin_config")
    mapfile -t plugin_dotfiles < <(yq -r '.dotfiles // [] | .[]' "$plugin_config")
    while IFS=$'\t' read -r key value; do
      [[ -z "$key" ]] && continue
      [[ -n "${OTHERFILES[$key]+x}" ]] && continue
      OTHERFILES["$key"]="$value"
    done < <(yq -r '.other // {} | to_entries[] | "\(.key)\t\(.value)"' "$plugin_config")

    CONFIGS+=("${plugin_configs[@]}")
    DOTFILES+=("${plugin_dotfiles[@]}")
  done

  if ((${#CONFIGS[@]})); then
    mapfile -t CONFIGS < <(printf '%s\n' "${CONFIGS[@]}" | awk 'NF && !seen[$0]++')
  fi

  if ((${#DOTFILES[@]})); then
    mapfile -t DOTFILES < <(printf '%s\n' "${DOTFILES[@]}" | awk 'NF && !seen[$0]++')
  fi
}

load_configuration() {
  # Load LCT configuration
  if [[ -f "${LCT_CONFIG_FILE}" ]]; then
    REMOTE_CONFIG_REPO=$(yq -r '.remote // ""' "${LCT_CONFIG_FILE}")
    mapfile -t CONFIGS < <(yq -r '.configs // [] | .[]' "${LCT_CONFIG_FILE}")
    mapfile -t DOTFILES < <(yq -r '.dotfiles // [] | .[]' "${LCT_CONFIG_FILE}")
    LCT_PACKAGE_MANAGER=$(yq -r '.packageManager // ""' "${LCT_CONFIG_FILE}")
    [[ "$LCT_PACKAGE_MANAGER" == "null" ]] && LCT_PACKAGE_MANAGER=""
    declare -gA OTHERFILES
    while IFS=$'\t' read -r key value; do
      [[ -z "$key" ]] && continue
      OTHERFILES["$key"]="$value"
    done < <(yq -r '.other // {} | to_entries[] | "\(.key)\t\(.value)"' "${LCT_CONFIG_FILE}")
    declare -ga PLUGINS
    mapfile -t PLUGINS < <(yq -r '.plugins // [] | .[]' "${LCT_CONFIG_FILE}")
    load_plugin_configs
  fi
}

load_env() {
  # Load LCT environment variables
  if [[ -f "${LCT_ENV_FILE}" ]]; then
    eval "$(yq -o=shell '.' ${LCT_ENV_FILE})"
  fi

  if [ -z "${LATEST_LCT_VERSION+x}" ]; then
    LATEST_LCT_VERSION=$(yq '.latest' "$LCT_VERSIONS_FILE")
    LATEST_LCT_VERSION_DIR="$LCT_VERSIONS_DIR/$LATEST_LCT_VERSION"
  fi

  if [[ -n "$REMOTE_CONFIG_REPO" && "$REMOTE_CONFIG_REPO" != "null" ]]; then
    set_origin_remote
  fi
}

setup_directories
load_configuration
load_env
