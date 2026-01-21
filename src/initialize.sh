# Function to handle errors
error_handler() {
  local exit_code=$? # Capture the exit code of the failed command
  echo "❌ ERROR: Command failed with exit code $exit_code on line $LINENO" >&2
  echo "❌ Failing command: $BASH_COMMAND" >&2
  echo "❌ Local bootstrap failed"
  exit $exit_code # Exit the script with the original error code
}

# Set the trap to call the error_handler function on ERR signal
trap 'error_handler' ERR

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

[[ -d "${LCT_SHARE_DIR}" ]] || mkdir -p "${LCT_SHARE_DIR}"
[[ -d "${LCT_CONFIG_DIR}" ]] || mkdir -p "${LCT_CONFIG_DIR}"
[[ -d "${LCT_VERSIONS_DIR}" ]] || mkdir -p "${LCT_VERSIONS_DIR}"
[[ -f "${LCT_ENV_FILE}" ]] || touch "${LCT_ENV_FILE}"
[[ -f "${LCT_CONFIG_FILE}" ]] || touch "${LCT_CONFIG_FILE}"
[[ -f "${LCT_VERSIONS_FILE}" ]] || touch "${LCT_VERSIONS_FILE}"

eval "$(yq -o=shell '.' ${LCT_CONFIG_FILE})"

if [ -z "${LATEST_LCT_VERSION+x}" ]; then
  LATEST_LCT_VERSION=$(yq '.latest' "$LCT_VERSIONS_FILE")
  LATEST_LCT_VERSION_DIR="$LCT_VERSIONS_DIR/$LATEST_LCT_VERSION"
fi
