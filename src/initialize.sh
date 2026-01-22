# Function to handle errors
error_handler() {
  local exit_code=$? # Capture the exit code of the failed command
  echo "❌ ERROR: Command failed with exit code $exit_code on line $LINENO" >&2
  echo "❌ Failing command: $BASH_COMMAND" >&2
  echo "❌ Local bootstrap failed"
  exit $exit_code # Exit the script with the original error code
}

# Expects:
#   REMOTE_CONFIG_REPO   e.g. https://github.com/org/repo.git  (or git@github.com:org/repo.git)
#   LCT_VERSIONS_DIR     path to an existing git working tree
set_origin_remote() {
  : "${REMOTE_CONFIG_REPO:?REMOTE_CONFIG_REPO is required}"
  : "${LCT_VERSIONS_DIR:?LCT_VERSIONS_DIR is required}"

  if [[ ! -d "$LCT_VERSIONS_DIR/.git" ]]; then
    echo "Not a git repo: $LCT_VERSIONS_DIR" >&2
    return 1
  fi

  local current
  current="$(git -C "$LCT_VERSIONS_DIR" remote get-url origin 2>/dev/null || true)"

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

  LCT_SHARE_DIR="${SHARE_DIR}/lct"
  LCT_CONFIG_DIR="${CONFIG_DIR}/lct"
  LCT_ENV_FILE="${LCT_SHARE_DIR}/env.yaml"
  LCT_CONFIG_FILE="${LCT_CONFIG_DIR}/config.yaml"
  LCT_VERSIONS_DIR="${LCT_SHARE_DIR}/config_versions"
  LCT_VERSIONS_FILE="${LCT_VERSIONS_DIR}/lct.yaml"
  LCT_BREW_FILE="${LCT_SHARE_DIR}/Brewfile"
}

setup_directories() {
  detect_directories

  [[ -d "${LCT_SHARE_DIR}" ]] || mkdir -p "${LCT_SHARE_DIR}"
  [[ -d "${LCT_CONFIG_DIR}" ]] || mkdir -p "${LCT_CONFIG_DIR}"
  [[ -d "${LCT_VERSIONS_DIR}" ]] || mkdir -p "${LCT_VERSIONS_DIR}"
  [[ -f "${LCT_ENV_FILE}" ]] || touch "${LCT_ENV_FILE}"
  [[ -f "${LCT_CONFIG_FILE}" ]] || touch "${LCT_CONFIG_FILE}"
  [[ -f "${LCT_VERSIONS_FILE}" ]] || touch "${LCT_VERSIONS_FILE}"
  [[ -d "$LCT_VERSIONS_DIR/.git" ]] || git init "$LCT_VERSIONS_DIR"
  [[ -f "${LCT_BREW_FILE}" ]] || touch "${LCT_BREW_FILE}"
}

load_configuration() {
  # Load LCT configuration
  if [[ -f "${LCT_CONFIG_FILE}" ]]; then
    REMOTE_CONFIG_REPO=$(yq '.remote' ${LCT_CONFIG_FILE})
    CONFIGS=($(yq -o=csv '.configs[]' ${LCT_CONFIG_FILE}))
    DOTFILES=($(yq -o=csv '.dotfiles[]' ${LCT_CONFIG_FILE}))
    declare -gA OTHERFILES
    eval "OTHERFILES=($(yq -r '.other | to_entries | .[] | "[\(.key)]=\"\(.value)\""' ~/.config/lct/config.yaml | paste -sd' ' -))"
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

  if [ $REMOTE_CONFIG_REPO != "null" ]; then
    set_origin_remote
  fi
}

trap 'error_handler' ERR
setup_directories
load_configuration
load_env
