#!/bin/bash
set -Eeuo pipefail

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

# Source the .env file to load variables
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found!"
  exit 1
fi

echo "Installing homebrew dependencies"
brew bundle
echo "✅ homebrew dependencies succesfully installed"

if [ -d "$SOFTWARE_DIR" ]; then
  echo " $SOFTWARE_DIR already exists"
else
  echo " Creating $SOFTWARE_DIR"
  mkdir -p $SOFTWARE_DIR
fi

CONFIGS=("alacritty" "mise" "zellij")

echo "Applying library configs"

for lib in "${CONFIGS[@]}"; do
  if [ -d "$CONFIG_DIR/$lib" ]; then
    echo "$lib config already exists"
  else
    echo "Applying $lib config"
    cp -r "./.config/$lib" "$CONFIG_DIR/"
  fi
done

echo "✅ Configs successfully copied"

# INSTALL MISE
if ! command -v mise &>/dev/null; then
  echo "installing mise"
  curl https://mise.run | sh
  echo 'eval "$(~/.local/bin/mise activate zsh)"' >>~/.zshrc
  mise install
  echo "✅ mise succesfully installed"
else
  echo "✅ mise already installed"
fi

# INSTALL alacritty
if [ -d "/Applications/Alacritty.app" ]; then
  echo "✅ alacritty already installed"
else
  echo "installing alacritty"
  git clone git@github.com:alacritty/alacritty.git $SOFTWARE_DIR/alacritty
  cd $SOFTWARE_DIR/alacritty
  make app
  cp -r target/release/osx/Alacritty.app /Applications/
  ln -s /Applications/Alacritty.app/Contents/MacOS/alacritty /usr/local/bin/alacritty
  sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
  cp extra/completions/_alacritty ~/.zsh_functions/_alacritty
  echo "✅ alacritty succesfully installed"
fi

echo "✅ Bootstrap complete"
echo "Feel free to add  the following to your zshrc file"
echo 'eval "$(zellij setup --generate-auto-start zsh)"'
