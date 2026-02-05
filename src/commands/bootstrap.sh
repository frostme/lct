CONFIG_VERSION=${args[--config]:-""}
FORCE=${args[--force]:-0}
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -z $CONFIG_VERSION ]]; then
  LATEST_LCT_VERSION="$CONFIG_VERSION"
fi

LATEST_LCT_VERSION_DIR="$TMP_DIR/$LATEST_LCT_VERSION"

echo "Starting Bootstrap Process"

echo "Decompressing latest configuration version: $LATEST_LCT_VERSION"
tar -xJf "$LCT_VERSIONS_DIR/$LATEST_LCT_VERSION.tar.xz" -C "$TMP_DIR"
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

echo "Installing homebrew dependencies"
brew bundle --file "$LCT_BREW_FILE"
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

for idx in "${!PLUGINS[@]}"; do
  plugin=${PLUGINS[$idx]}
  owner="$(echo "$plugin" | awk -F '[/.]' '{print $1}')"
  repo="$(echo "$plugin" | awk -F '[/.]' '{print $2}')"
  name="$(echo "$plugin" | awk -F '.' '{print $2}')"
  plugin_dir="$LCT_PLUGINS_DIR/$owner-$repo${name:+-$name}"
  eval "${plugin_dir}/main.sh"
done
# ##################################################

echo "✅ Bootstrap complete"
echo "Feel free to add  the following to your zshrc file"
echo 'eval "$(lct setup)"'
