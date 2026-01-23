libname=${args[library]}

brew install $libname
brew bundle add $libname --file=$LCT_BREW_FILE
