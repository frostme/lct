enable_auto_colors

LCT_PACKAGE_MANAGER=""
LCT_VERBOSE="${LCT_VERBOSE:-0}"

lct_stacktrace() {
  local exit_status="$?"
  local i=0
  local caller_output line func file
  local trace_lines=()

  trace_lines+=("command=${BASH_COMMAND}")
  trace_lines+=("source=${BASH_SOURCE[0]}:${BASH_LINENO[0]}")
  trace_lines+=("function=${FUNCNAME[1]}")
  trace_lines+=("exit_status=${exit_status}")

  printf "%s:%s in \`%s\`: %s\n" "${BASH_SOURCE[0]}" "${BASH_LINENO[0]}" "${FUNCNAME[1]}" "$BASH_COMMAND" >&2
  printf "\nStack trace:\n" >&2
  while caller_output="$(caller $i)"; do
    read -r line func file <<<"$caller_output"
    printf "\tfrom %s:%s in \`%s\`\n" "$file" "$line" "$func" >&2
    trace_lines+=("frame=${file}:${line}:${func}")
    i=$((i + 1))
  done

  if declare -F lct_log_exception >/dev/null 2>&1; then
    local joined
    joined="$(printf '%s | ' "${trace_lines[@]}")"
    joined="${joined% | }"
    lct_log_exception "Unhandled error with stacktrace: ${joined}"
  fi

  exit "$exit_status"
}

enable_lct_stacktrace() {
  trap 'lct_stacktrace' ERR
  set -o errtrace
  set -o errexit
}

enable_lct_stacktrace

detect_verbose_flag() {
  local arg
  for arg in "$@"; do
    case "$arg" in
    --verbose | -V)
      LCT_VERBOSE=1
      break
      ;;
    esac
  done
}

detect_verbose_flag "${command_line_args[@]:-}"

# -----------------------------
# Function: set_origin_remote
# Description:
#   - Configures the origin remote of the git repository in LCT_REMOTE_DIR to match REMOTE_CONFIG_REPO.
# Preconditions:
#   - REMOTE_CONFIG_REPO: Git URL (e.g., https://github.com/org/repo.git or git@github.com:org/repo.git).
#   - LCT_REMOTE_DIR: Path to a git working tree.
# -----------------------------
set_origin_remote() {
  # Validate required environment variables
  : "${REMOTE_CONFIG_REPO:?REMOTE_CONFIG_REPO is required}"
  : "${LCT_REMOTE_DIR:?LCT_REMOTE_DIR is required}"

  # Check if LCT_REMOTE_DIR is a valid git repository
  if [[ ! -d "$LCT_REMOTE_DIR/.git" ]]; then
    echo "Error: Not a git repo: $LCT_REMOTE_DIR" >&2
    return 1
  fi

  local current

  # Get current remote URL, if it exists
  current="$(git -C "$LCT_REMOTE_DIR" remote get-url origin 2>/dev/null || true)"

  # Update or set the remote as needed
  if [[ -z "$current" ]]; then
    git -C "$LCT_REMOTE_DIR" remote add origin "$REMOTE_CONFIG_REPO" &>/dev/null
  elif [[ "$current" != "$REMOTE_CONFIG_REPO" ]]; then
    git -C "$LCT_REMOTE_DIR" remote set-url origin "$REMOTE_CONFIG_REPO" &>/dev/null
  fi
}

detect_directories() {
  lct_log_debug "Detecting base directories from environment and defaults"
  if [ -z "${SOFTWARE_DIR+x}" ]; then
    SOFTWARE_DIR="$HOME/software"
  fi

  if [ -z "${CONFIG_DIR+x}" ]; then
    CONFIG_DIR="$HOME/.config"
  fi

  if [ -z "${SHARE_DIR+x}" ]; then
    SHARE_DIR="$HOME/.local/share"
  fi

  if [ -z "${CODE_DIR+x}" ]; then
    CODE_DIR="$HOME/code"
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
  LCT_STATE_DIR="${STATE_DIR}/lct"
  LCT_CACHE_DIR="${CACHE_DIR}/lct"
  LCT_ENV_FILE="${LCT_SHARE_DIR}/env.yaml"
  LCT_CONFIG_FILE="${LCT_CONFIG_DIR}/config.yaml"
  LCT_REMOTE_DIR="${LCT_SHARE_DIR}/remote"
  LCT_REMOTE_SECRETS_DIR="${LCT_REMOTE_DIR}/secrets"
  LCT_BREW_FILE="${LCT_SHARE_DIR}/Brewfile"
  LCT_ALIAS_FILE="${LCT_SHARE_DIR}/alias.yaml"
  LCT_INIT_FILE="${LCT_SHARE_DIR}/.init_done"
  LCT_PLUGINS_CACHE_DIR="${LCT_CACHE_DIR}/plugins"
  LCT_PLUGINS_DIR="${LCT_SHARE_DIR}/plugins"
  LCT_MODULES_CACHE_DIR="${LCT_CACHE_DIR}/modules"
  LCT_MODULES_DIR="${LCT_SHARE_DIR}/modules"
  LCT_MODULES_BIN_DIR="${LCT_MODULES_DIR}/bin"
  LCT_DEBUG_LOG_FILE="${LCT_STATE_DIR}/debug.log"
  lct_init_logging
  lct_log_debug "Resolved log file path: ${LCT_DEBUG_LOG_FILE}"
}

setup_directories() {
  lct_log_debug "Ensuring lct directories and base files exist"
  detect_directories

  [[ -d "${LCT_SOFTWARE_DIR}" ]] || mkdir -p "${LCT_SOFTWARE_DIR}"
  [[ -d "${LCT_SHARE_DIR}" ]] || mkdir -p "${LCT_SHARE_DIR}"
  [[ -d "${LCT_CONFIG_DIR}" ]] || mkdir -p "${LCT_CONFIG_DIR}"
  [[ -d "${LCT_STATE_DIR}" ]] || mkdir -p "${LCT_STATE_DIR}"
  [[ -d "${LCT_REMOTE_DIR}" ]] || mkdir -p "${LCT_REMOTE_DIR}"
  [[ -d "${LCT_REMOTE_SECRETS_DIR}" ]] || mkdir -p "${LCT_REMOTE_SECRETS_DIR}"
  [[ -f "${LCT_ENV_FILE}" ]] || touch "${LCT_ENV_FILE}"
  [[ -f "${LCT_CONFIG_FILE}" ]] || touch "${LCT_CONFIG_FILE}"
  [[ -f "${LCT_ALIAS_FILE}" ]] || touch "${LCT_ALIAS_FILE}"
  [[ -d "$LCT_REMOTE_DIR/.git" ]] || git init -q -b main "$LCT_REMOTE_DIR"
  [[ -f "${LCT_REMOTE_DIR}/lct.yaml" ]] && rm -f "${LCT_REMOTE_DIR}/lct.yaml"
  [[ -f "${LCT_BREW_FILE}" ]] || touch "${LCT_BREW_FILE}"
  [[ -d "${LCT_CACHE_DIR}" ]] || mkdir -p "${LCT_CACHE_DIR}"
  [[ -d "${LCT_PLUGINS_DIR}" ]] || mkdir -p "${LCT_PLUGINS_DIR}"
  [[ -d "${LCT_PLUGINS_CACHE_DIR}" ]] || mkdir -p "${LCT_PLUGINS_CACHE_DIR}"
  [[ -d "${LCT_MODULES_DIR}" ]] || mkdir -p "${LCT_MODULES_DIR}"
  [[ -d "${LCT_MODULES_BIN_DIR}" ]] || mkdir -p "${LCT_MODULES_BIN_DIR}"
  [[ -d "${LCT_MODULES_CACHE_DIR}" ]] || mkdir -p "${LCT_MODULES_CACHE_DIR}"
  lct_log_debug "Directory setup complete"
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
    mapfile -t plugin_other_files < <(yq -r '.other // [] | .[]?' "$plugin_config")

    CONFIGS+=("${plugin_configs[@]}")
    DOTFILES+=("${plugin_dotfiles[@]}")
    OTHERFILES+=("${plugin_other_files[@]}")
  done

  if ((${#CONFIGS[@]})); then
    mapfile -t CONFIGS < <(printf '%s\n' "${CONFIGS[@]}" | awk 'NF && !seen[$0]++')
  fi

  if ((${#DOTFILES[@]})); then
    mapfile -t DOTFILES < <(printf '%s\n' "${DOTFILES[@]}" | awk 'NF && !seen[$0]++')
  fi

  if ((${#OTHERFILES[@]})); then
    mapfile -t OTHERFILES < <(printf '%s\n' "${OTHERFILES[@]}" | awk 'NF && !seen[$0]++')
  fi
}

load_configuration() {
  lct_log_debug "Loading config from ${LCT_CONFIG_FILE}"
  # Load LCT configuration
  if [[ -f "${LCT_CONFIG_FILE}" ]]; then
    REMOTE_CONFIG_REPO=$(yq -r '.remote // ""' "${LCT_CONFIG_FILE}")
    mapfile -t CONFIGS < <(yq -r '.configs // [] | .[]' "${LCT_CONFIG_FILE}")
    mapfile -t DOTFILES < <(yq -r '.dotfiles // [] | .[]' "${LCT_CONFIG_FILE}")
    LCT_PACKAGE_MANAGER=$(yq -r '.packageManager // ""' "${LCT_CONFIG_FILE}")
    [[ "$LCT_PACKAGE_MANAGER" == "null" ]] && LCT_PACKAGE_MANAGER=""
    declare -ga OTHERFILES
    mapfile -t OTHERFILES < <(yq -r '.other // [] | .[]?' "${LCT_CONFIG_FILE}")
    declare -ga SECRETS
    mapfile -t SECRETS < <(yq -r '.secrets // [] | .[]' "${LCT_CONFIG_FILE}")
    declare -ga PLUGINS
    mapfile -t PLUGINS < <(yq -r '.plugins // [] | .[]' "${LCT_CONFIG_FILE}")
    declare -ga MODULES
    mapfile -t MODULES < <(yq -r '.modules // [] | .[]' "${LCT_CONFIG_FILE}")
    declare -ga PROJECTS
    mapfile -t PROJECTS < <(yq -r '.projects // [] | .[]' "${LCT_CONFIG_FILE}")
    load_plugin_configs
    if ((${#SECRETS[@]})); then
      mapfile -t SECRETS < <(printf '%s\n' "${SECRETS[@]}" | awk 'NF && !seen[$0]++')
    fi
    lct_log_debug "Loaded config arrays: configs=${#CONFIGS[@]} dotfiles=${#DOTFILES[@]} other=${#OTHERFILES[@]} secrets=${#SECRETS[@]} plugins=${#PLUGINS[@]} modules=${#MODULES[@]} projects=${#PROJECTS[@]}"
  fi
}

load_env() {
  lct_log_debug "Loading environment overrides from ${LCT_ENV_FILE}"
  # Load LCT environment variables
  if [[ -f "${LCT_ENV_FILE}" ]]; then
    while IFS='=' read -r key value; do
      if [[ -z "$key" && -z "$value" ]]; then
        continue
      fi
      if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "Error: Invalid environment key in ${LCT_ENV_FILE}: ${key}" >&2
        return 1
      fi
      export "${key}=${value}"
    done < <(yq -r 'to_entries[] | "\(.key)=\(.value|tostring)"' "${LCT_ENV_FILE}")
  fi

  if [[ -n "$REMOTE_CONFIG_REPO" && "$REMOTE_CONFIG_REPO" != "null" ]]; then
    lct_log_debug "Configuring origin remote for ${LCT_REMOTE_DIR}"
    set_origin_remote
  fi
}

setup_directories
load_configuration
load_env
lct_log_debug "Initialization complete (verbose=${LCT_VERBOSE})"
