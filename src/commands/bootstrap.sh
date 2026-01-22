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

# INSTALL OH-MY-ZSH
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "✅ oh-my-zsh already installed"
else
  echo "installing oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/master/tools/insall.sh)"
  echo "✅ oh-my-zsh succesfully installed"
fi

# INSTALL ZSH ITEMS

if [ -d "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions" ]; then
  echo "✅ zsh-completions already installed"
else
  echo "installing zsh-completions"
  git clone https://github.com/zsh-users/zsh-completions.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
  echo "✅ zsh-completions succesfully installed"
fi

if [ -d "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-syntax-highlighting" ]; then
  echo "✅ zsh-syntax-highlighting already installed"
else
  echo "installing zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  echo "✅ zsh-syntax-highlighting successfully installed"
fi

if [ -d "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-autosuggestions" ]; then
  echo "✅ zsh-autosuggestions already installed"
else
  echo "installing zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  echo "✅ zsh-autosuggestions successfully installed"
fi

# INSTALL POWERLEVEL10K
if [ -d "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/themes/powerlevel10k" ]; then
  echo "✅ powerlevel10k already installed"
else
  echo "installing powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  echo "✅ powerlevel10k succesfully installed"
fi

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
  echo "✅ alacritty succesfully \installed"
fi

# INSTALL jrnl
if ! command -v jrnl &>/dev/null; then
  echo "installing jrnl"
  pip install jrnl
  echo "✅ jrnl succesfully installed"
else
  echo "✅ jrnl already installed"
fi

# INSTALL lazyvim
if [ -f "$CONFIG_DIR/nvim/lazyvim.json" ]; then
  echo "✅ LazyVim already installed"
else
  echo "Installing LavyVim"
  echo "Applying LazyVim config"
  echo "Backing up existing nvim config if it exists"
  if [ -d $CONFIG_DIR/nvim ]; then
    mv $CONFIG_DIR/nvim $CONFIG_DIR/nvim.bak
  fi

  if [ -d $SHARE_DIR/nvim ]; then
    mv $SHARE_DIR/nvim $SHARE_DIR/nvim.bak
  fi

  if [ -d "$STATE_DIR/nvim" ]; then
    mv "$STATE_DIR/nvim" "$STATE_DIR/nvim.bak"
  fi

  if [ -d "$CACHE_DIR/nvim" ]; then
    mv "$CACHE_DIR/nvim" "$CACHE_DIR/nvim.bak"
  fi

  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rmz -f ~/.config/nvim/.git

  cp -r "$LATEST_LCT_VERSION_DIR/lazyvim/lazyvim.json" "$CONFIG_DIR/nvim/lazyvim.json"
  cp -r "$LATEST_LCT_VERSION_DIR/lazyvim/lua" "$CONFIG_DIR/nvim/lua"
fi

echo "✅ Bootstrap complete"
echo "Feel free to add  the following to your zshrc file"
echo 'eval "$(lct setup)"'
