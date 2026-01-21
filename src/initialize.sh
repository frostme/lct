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

if [ -z "${LCT_DIR+x}" ]; then
  LCT_DIR="$HOME/code/personal/local"
fi

if [ -z "${LATEST_LCT_VERSION+x}" ]; then
  LATEST_LCT_VERSION=$(yq '.latest' "$LCT_DIR/config_versions/lct.yaml")
  LATEST_LCT_VERSION_DIR="$LCT_DIR/config_versions/$LATEST_LCT_VERSION"
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

[[ -d "${LCT_SHARE_DIR}" ]] || mkdir -p "${LCT_SHARE_DIR}"
[[ -d "${LCT_CONFIG_DIR}" ]] || mkdir -p "${LCT_CONFIG_DIR}"
[[ -f "${LCT_ENV_FILE}" ]] || touch "${LCT_ENV_FILE}"
