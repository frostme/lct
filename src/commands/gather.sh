latest_version=$(yq '.latest' "$LCT_VERSIONS_FILE")
this_version=$(date +%Y.%m.%d)

FORCE=${args[--force]:-0}
VERSION_DIR="$LCT_VERSIONS_DIR/$this_version"
LCT_FILES=("$LCT_BREW_FILE" "$LCT_CONFIG_FILE")

require_gum() {
  if ! command -v gum >/dev/null 2>&1; then
    echo "gum is required. Install via Brewfile (brew bundle)." >&2
    exit 1
  fi
}

require_gum

if [ "$this_version" == "$latest_version" ]; then
  if [[ $FORCE -eq 1 ]]; then
    gum style --foreground 214 "⚠ Forcing config gather despite being up to date"
  else
    gum style --foreground 82 "✅ Configs are already up to date"
    exit 0
  fi
fi

gum style --border normal --padding "1 2" --margin "0 0 1 0" --foreground 212 "Gathering configs for version: $this_version"

gum spin --spinner dot --title "Preparing directories" -- bash -c "mkdir -p \"$VERSION_DIR\" \"$VERSION_DIR/config\" \"$VERSION_DIR/dotfiles\" \"$VERSION_DIR/lazyvim\""

gum style --border normal --padding "0 1" "Gathering LCT files"
for file in "${LCT_FILES[@]}"; do
  file_name="$(basename "$file")"
  gum spin --spinner dot --title "Copying $file_name" -- cp -r "$file" "$VERSION_DIR/"
done

gum style --border normal --padding "0 1" "Gather library configs"

for lib in "${CONFIGS[@]}"; do
  gum spin --spinner dot --title "Copying $lib config" -- cp -r "$CONFIG_DIR/$lib" "$VERSION_DIR/config/"
done

gum style --foreground 82 "✅ Configs successfully gathered"

gum style --border normal --padding "0 1" "Gathering dotfiles"

for file in "${DOTFILES[@]}"; do
  gum spin --spinner dot --title "Copying $file" -- cp -r "$HOME/$file" "$VERSION_DIR/dotfiles/"
done

gum style --foreground 82 "✅ Dotfiles successfully gathered"

gum style --border normal --padding "0 1" "Gathering other files"
for key in "${!OTHERFILES[@]}"; do
  src_file="$HOME/${OTHERFILES[$key]}"
  dest_file="$VERSION_DIR/$key"
  dest_dir=$(dirname "$dest_file")
  gum spin --spinner dot --title "Copying $src_file to $dest_file" -- mkdir -p "$dest_dir"
  gum spin --spinner dot --title "Adding $key" -- cp -r "$src_file" "$dest_file"
done

gum style --foreground 82 "✅ Other files successfully gathered"

gum spin --spinner line --title "Compressing gathered configuration" -- tar -cJf "$LCT_VERSIONS_DIR/$this_version.tar.xz" -C "$LCT_VERSIONS_DIR" "$this_version"
gum spin --spinner dot --title "Cleaning up temporary files" -- rm -rf "$VERSION_DIR"
gum style --foreground 82 "✅ Successfully compressed configuration"

# Update latest version in lct.yaml
yq -i ".latest = \"$this_version\"" "$LCT_VERSIONS_FILE"

git -C "$LCT_VERSIONS_DIR" add .
git -C "$LCT_VERSIONS_DIR" commit -m "Gather configs for version $this_version" || echo "No changes to commit"
git -C "$LCT_VERSIONS_DIR" push origin main || echo "No remote repository configured, skipping push"
gum join --vertical \
  "$(gum style --foreground 82 "✅ Config gather for version $this_version completed successfully")" \
  "$(gum style --foreground 99 "Archive available at $LCT_VERSIONS_DIR/$this_version.tar.xz")"
