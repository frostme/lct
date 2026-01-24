CONFIG_VERSION=${args[--config]:-""}
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
for key in "${!PLUGINS[@]}"; do
  version="${PLUGINS[$key]}"
  plugin=${key}
  if [ -f "$LCT_PLUGINS_DIR/$plugin-$version" ]; then
    echo "✅ $plugin already installed"
  else
    echo "installing $plugin"
    [[ -d $TMP_DIR/registry ]] || git clone -q $REGISTRY $TMP_DIR/registry

    # TODO: change to downloading from a central repo
    tar -xJf "$TMP_DIR/registry/plugins/$plugin-$version.tar.xz" -C "$LCT_PLUGINS_DIR/"
  fi
  eval "$LCT_PLUGINS_DIR/$plugin-$version"
done
# ##################################################

echo "✅ Bootstrap complete"
echo "Feel free to add  the following to your zshrc file"
echo 'eval "$(lct setup)"'
