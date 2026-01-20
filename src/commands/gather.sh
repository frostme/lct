latest_version=$(yq '.latest' "$LCT_DIR/config_versions/lct.yaml")
this_version=$(date +%Y.%m.%d)

FORCE=${args[--force]:-0}
VERSION_DIR="$LCT_DIR/config_versions/$this_version"

if [ "$this_version" == "$latest_version" ]; then
  if [[ $FORCE -eq 1 ]]; then
    echo "⚠ Forcing config gather despite being up to date"
  else
    echo "✅ Configs are already up to date"
    exit 0
  fi
else
  echo "Gathering configs for new version: $this_version"
  mkdir -p "$VERSION_DIR"
  mkdir -p "$VERSION_DIR/config"
  mkdir -p "$VERSION_DIR/dotfiles"
  mkdir -p "$VERSION_DIR/lazyvim"
fi

CONFIGS=("alacritty" "mise" "zellij")

echo "Gather library configs"

for lib in "${CONFIGS[@]}"; do
  echo "Copying $lib config"
  cp -r "$CONFIG_DIR/$lib" "$VERSION_DIR/config/"
done

echo "✅ Configs successfully gathered"

DOTFILES=(".zshrc" ".p10k.zsh" ".gitconfig" ".gitignore_global")

echo "Gathering dotfiles"

for file in "${DOTFILES[@]}"; do
  echo "Copying $file"
  cp "$HOME/$file" "$VERSION_DIR/dotfiles/"
done

echo "✅ Dotfiles successfully gathered"

LAZYVIM_DIR="$CONFIG_DIR/nvim"

echo "Gathering LazyVim config"
cp -r "$LAZYVIM_DIR/lazyvim.json" "$VERSION_DIR/lazyvim/"
cp -r "$LAZYVIM_DIR/lua" "$VERSION_DIR/lazyvim/"

echo "✅ LazyVim config successfully gathered"

# Update latest version in lct.yaml
yq -i ".latest = \"$this_version\"" "$LCT_DIR/config_versions/lct.yaml"

echo "✅ Config gather for version $this_version completed successfully"
