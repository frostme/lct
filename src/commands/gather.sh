run_init_if_needed

this_version=$(date +%Y.%m.%d)
FORCE=${args[--force]:-0}
VERSION_DIR="$LCT_VERSIONS_DIR/$this_version"
LCT_FILES=("$LCT_BREW_FILE" "$LCT_CONFIG_FILE")

copy_entry() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp -R "$src" "$dest"
  else
    echo "⚠ Skipping missing ${label}: $src"
  fi
}

if [[ -d "$VERSION_DIR" ]]; then
  if [[ $FORCE -eq 1 ]]; then
    echo "⚠ Forcing config gather despite existing version: $this_version"
  else
    echo "✅ Configs are already gathered for version $this_version"
    exit 0
  fi
fi

gum_title "Gathering configs for new version: $this_version"
rm -rf "$VERSION_DIR"
mkdir -p "$VERSION_DIR"
mkdir -p "$VERSION_DIR/dotfiles"
mkdir -p "$VERSION_DIR/other"

echo "Gathering LCT files"
for file in "${LCT_FILES[@]}"; do
  echo "Copying $(basename "$file")"
  copy_entry "$file" "$VERSION_DIR/$(basename "$file")" "LCT file"
done

echo "Gathering library configs"
for lib in "${CONFIGS[@]}"; do
  src_path="$CONFIG_DIR/$lib"
  dest_path="$VERSION_DIR/$lib"
  echo "Copying $lib config"
  copy_entry "$src_path" "$dest_path" "config"
done
echo "✅ Configs successfully gathered"

echo "Gathering dotfiles"
for file in "${DOTFILES[@]}"; do
  src_path="$HOME/$file"
  dest_path="$VERSION_DIR/dotfiles/$file"
  echo "Copying $file"
  copy_entry "$src_path" "$dest_path" "dotfile"
done
echo "✅ Dotfiles successfully gathered"

echo "Gathering other files"
for key in "${!OTHERFILES[@]}"; do
  src_file="$HOME/${OTHERFILES[$key]}"
  dest_file="$VERSION_DIR/other/$key"
  echo "Copying $src_file to $dest_file"
  copy_entry "$src_file" "$dest_file" "other file"
done
echo "✅ Other files successfully gathered"

# keep config_versions as a plain git working tree (no compression, no lct.yaml metadata)
rm -f "$LCT_VERSIONS_DIR/lct.yaml"

git -C "$LCT_VERSIONS_DIR" add .
git -C "$LCT_VERSIONS_DIR" commit -m "Gather configs for version $this_version" || echo "No changes to commit"
git -C "$LCT_VERSIONS_DIR" push origin main || echo "No remote repository configured, skipping push"

if gum_available; then
  gum_join_vertical     "$(gum style --foreground 121 "✅ Config gather for version $this_version completed successfully")"     "$(gum style --foreground 244 "Stored in repository: $LCT_VERSIONS_DIR/$this_version")"
else
  echo "✅ Config gather for version $this_version completed successfully"
fi
