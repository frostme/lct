#!/bin/bash
set -Eeuo pipefail

# Function to handle errors
error_handler() {
  local exit_code=$? # Capture the exit code of the failed command
  echo "❌ ERROR: Command failed with exit code $exit_code on line $LINENO" >&2
  echo "❌ Failing command: $BASH_COMMAND" >&2
  echo "❌ Local gather failed"
  exit $exit_code # Exit the script with the original error code
}

# Set the trap to call the error_handler function on ERR signal
trap 'error_handler' ERR

# Source the .env file to load variables
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found!"
  exit 1
fi

CONFIGS=("alacritty" "mise" "zellij")

echo "Gather library configs"

for lib in "${CONFIGS[@]}"; do
  echo "--- Copying $lib config"
  cp -r "$CONFIG_DIR/$lib" "./.config/"
done

echo "✅ Configs successfully gathered"
