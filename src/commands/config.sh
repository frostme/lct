lib_name="${args[lib_name]:-lct}"

# List of possible extensions
exts="yaml json kdl toml ini env sh fish ps1 conf cfg xml properties plist yml"

# Construct array of possible config paths
candidates=()
for ext in $exts; do
  candidates+=("$CONFIG_DIR/$lib_name/config.$ext")
  candidates+=("$CONFIG_DIR/$lib_name/$lib_name.$ext")
  candidates+=("$CONFIG_DIR/$lib_name.$ext") # Sometimes config is at ~/.config/libname.ext
done

# Find the first existing config file
for path in "${candidates[@]}"; do
  if [ -f "$path" ]; then
    eval "$EDITOR \"$path\""
    exit 0
  fi
done

if gum_available; then
  picked_path=$(gum_pick_file "$CONFIG_DIR" --file)
  if [[ -n "$picked_path" ]]; then
    eval "$EDITOR \"$picked_path\""
    exit 0
  fi
fi

echo "No config file found for $lib_name in $CONFIG_DIR"
