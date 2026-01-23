libname=${args[library]}

brew uninstall $libname
brew bundle remove $libname --file=$LCT_BREW_FILE
