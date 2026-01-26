latest_version=$(yq '.latest' "$LCT_VERSIONS_FILE")
this_version=$(date +%Y.%m.%d)

FORCE=${args[--force]:-0}
VERSION_DIR="$LCT_VERSIONS_DIR/$this_version"
LCT_FILES=("$LCT_BREW_FILE" "$LCT_CONFIG_FILE")

if [ "$this_version" == "$latest_version" ]; then
  if [[ $FORCE -eq 1 ]]; then
    echo "⚠ Forcing config gather despite being up to date"
  else
    echo "✅ Configs are already up to date"
    exit 0
  fi
fi

echo "Gathering configs for new version: $this_version"
mkdir -p "$VERSION_DIR"
mkdir -p "$VERSION_DIR/config"
mkdir -p "$VERSION_DIR/dotfiles"
mkdir -p "$VERSION_DIR/lazyvim"

echo "Gathering LCT files"
for file in "${LCT_FILES[@]}"; do
  echo "Copying $(basename "$file")"
  cp -r "$file" "$VERSION_DIR/"
done

echo "Gather library configs"

for lib in "${CONFIGS[@]}"; do
  echo "Copying $lib config"
  cp -r "$CONFIG_DIR/$lib" "$VERSION_DIR/config/"
done

echo "✅ Configs successfully gathered"

echo "Gathering dotfiles"

for file in "${DOTFILES[@]}"; do
  echo "Copying $file"
  cp -r "$HOME/$file" "$VERSION_DIR/dotfiles/"
done

echo "✅ Dotfiles successfully gathered"

echo "Gathering other files"
for key in "${!OTHERFILES[@]}"; do
  src_file="$HOME/${OTHERFILES[$key]}"
  dest_file="$VERSION_DIR/$key"
  dest_dir=$(dirname "$dest_file")
  echo "Copying $src_file to $dest_file"
  mkdir -p "$dest_dir"
  cp -r "$src_file" "$dest_file"
done

echo "✅ Other files successfully gathered"

echo "Compressing gathered configuration"
tar -cJf "$LCT_VERSIONS_DIR/$this_version.tar.xz" -C "$LCT_VERSIONS_DIR" "$this_version"
rm -rf "$VERSION_DIR"
echo "✅ Successfully compressed configuration"

# Update latest version in lct.yaml
yq -i ".latest = \"$this_version\"" "$LCT_VERSIONS_FILE"

git -C "$LCT_VERSIONS_DIR" add .
git -C "$LCT_VERSIONS_DIR" commit -m "Gather configs for version $this_version" || echo "No changes to commit"
git -C "$LCT_VERSIONS_DIR" push origin main || echo "No remote repository configured, skipping push"
echo "✅ Config gather for version $this_version completed successfully"
