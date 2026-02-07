CONFIG_VERSION=${args[--config]:-""}
FORCE=${args[--force]:-0}
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

require_gum() {
  if ! command -v gum >/dev/null 2>&1; then
    echo "gum is required. Install via Brewfile (brew bundle)." >&2
    exit 1
  fi
}

require_gum

run_init_if_needed

if [[ ! -z $CONFIG_VERSION ]]; then
  LATEST_LCT_VERSION="$CONFIG_VERSION"
fi

LATEST_LCT_VERSION_DIR="$TMP_DIR/$LATEST_LCT_VERSION"

gum style --border normal --padding "1 2" --margin "0 0 1 0" --foreground 212 "Starting Bootstrap Process"

gum spin --spinner dot --title "Decompressing configuration $LATEST_LCT_VERSION" -- tar -xJf "$LCT_VERSIONS_DIR/$LATEST_LCT_VERSION.tar.xz" -C "$TMP_DIR"
gum style --foreground 82 "✅ Decompression complete"

if [ -f "$LCT_BREW_FILE" ] && [ $FORCE == 0 ]; then
  gum style --foreground 99 "Using existing Brewfile at $LCT_BREW_FILE"
else
  gum spin --spinner pulse --title "Copying Brewfile from $LATEST_LCT_VERSION" -- cp "$LATEST_LCT_VERSION_DIR/Brewfile" "$LCT_BREW_FILE"
fi

if [ -f "$LCT_CONFIG_FILE" ] && [ $FORCE == 0 ]; then
  gum style --foreground 99 "Using existing config.yaml at $LCT_CONFIG_FILE"
else
  gum spin --spinner pulse --title "Copying config.yaml from $LATEST_LCT_VERSION" -- cp "$LATEST_LCT_VERSION_DIR/config.yaml" "$LCT_CONFIG_FILE"
fi

gum spin --spinner line --title "Installing homebrew dependencies" -- brew bundle --file "$LCT_BREW_FILE"
gum style --foreground 82 "✅ homebrew dependencies succesfully installed"

if [ -d "$SOFTWARE_DIR" ]; then
  gum style --foreground 99 "$SOFTWARE_DIR already exists"
else
  gum spin --title "Creating $SOFTWARE_DIR" -- mkdir -p "$SOFTWARE_DIR"
fi

gum style --border normal --padding "0 1" "Applying library configs"

for lib in "${CONFIGS[@]}"; do
  if [ -d "$CONFIG_DIR/$lib" ]; then
    gum style --foreground 99 "$lib config already exists"
  else
    gum spin --spinner dot --title "Applying $lib config" -- cp -r "$LATEST_LCT_VERSION_DIR/$lib" "$CONFIG_DIR/"
  fi
done

gum style --foreground 82 "✅ Configs successfully copied"

############# plugin installations #############
total_plugins=${#PLUGINS[@]}
loaded=0

plugin_installation
load_plugins

# ##################################################

gum join --vertical \
  "$(gum style --foreground 82 "✅ Bootstrap complete")" \
  "$(gum style --foreground 99 "Add the following to your zshrc file")" \
  "$(gum style --foreground 87 'eval "$(lct setup)"')"
