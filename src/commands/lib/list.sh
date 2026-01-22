lib_type=${args[--type]:-"all"}
eval $(echo "brew bundle list --file=$LCT_BREW_FILE --${lib_type}")
