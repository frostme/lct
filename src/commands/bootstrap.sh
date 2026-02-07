CONFIG_VERSION=${args[--config]:-""}
FORCE=${args[--force]:-0}
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

run_init_if_needed

if [[ ! -z $CONFIG_VERSION ]]; then
  LATEST_LCT_VERSION="$CONFIG_VERSION"
fi

LATEST_LCT_VERSION_DIR="$TMP_DIR/$LATEST_LCT_VERSION"

gum_title "Starting Bootstrap Process"

gum_spinner "Decompressing $LATEST_LCT_VERSION" tar -xJf "$LCT_VERSIONS_DIR/$LATEST_LCT_VERSION.tar.xz" -C "$TMP_DIR"
echo "✅ Decompression complete"

if [ -f "$LCT_BREW_FILE" ] && [ $FORCE == 0 ]; then
  echo "Using existing Brewfile at $LCT_BREW_FILE"
else
  echo "No Brewfile found, using the one from the latest config version"
  cp "$LATEST_LCT_VERSION_DIR/Brewfile" "$LCT_BREW_FILE"
fi

if [ -f "$LCT_CONFIG_FILE" ] && [ $FORCE == 0 ]; then
  echo "Using existing config.yaml at $LCT_CONFIG_FILE"
else
  echo "No config.yaml found, using the one from the latest config version"
  cp "$LATEST_LCT_VERSION_DIR/config.yaml" "$LCT_CONFIG_FILE"
fi

gum_spinner "Installing homebrew dependencies" brew bundle --file "$LCT_BREW_FILE"
echo "✅ homebrew dependencies succesfully installed"

if [ -d "$SOFTWARE_DIR" ]; then
  echo " $SOFTWARE_DIR already exists"
else
  echo " Creating $SOFTWARE_DIR"
  mkdir -p $SOFTWARE_DIR
fi

echo "Applying library configs"

for lib in "${CONFIGS[@]}"; do
  if [ -d "$CONFIG_DIR/$lib" ]; then
    echo "$lib config already exists"
  else
    echo "Applying $lib config"
    cp -r "$LATEST_LCT_VERSION_DIR/$lib" "$CONFIG_DIR/"
  fi
done

echo "✅ Configs successfully copied"

############# plugin installations #############
total_plugins=${#PLUGINS[@]}
loaded=0

plugin_installation
load_plugins

# ##################################################

echo "✅ Bootstrap complete"
if gum_available; then
  gum_join_vertical \
    "$(gum style --foreground 212 'Add the following to your shell to complete setup:')" \
    "$(gum style --foreground 121 'eval \"$(lct setup)\"')"
else
  echo "Feel free to add  the following to your zshrc file"
  echo 'eval "$(lct setup)"'
fi
