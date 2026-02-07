if command -v mise &>/dev/null; then
  echo "mise is already installed"
else
  cargo install cargo-binstall
  cargo binstall mise
fi

if command -v brew &>/dev/null; then
  echo "Homebrew is already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle
mise install
