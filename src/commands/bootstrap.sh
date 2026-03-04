FORCE=${args[--force]:-0}
lct_log_debug "bootstrap command started (force=${FORCE})"

run_init_if_needed

REMOTE_CONFIGS_DIR="$LCT_REMOTE_DIR/configs"

gum_title "Starting Bootstrap Process"

if [[ ! -d "$REMOTE_CONFIGS_DIR" ]]; then
  lct_log_error "Bootstrap aborted: missing remote configs dir ${REMOTE_CONFIGS_DIR}"
  echo "❌ No gathered remote configuration found at $REMOTE_CONFIGS_DIR" >&2
  echo "Run 'lct gather' first to populate the remote repository." >&2
  exit 1
fi

if git -C "$LCT_REMOTE_DIR" remote get-url origin >/dev/null 2>&1; then
  lct_log_debug "Pulling latest remote config repository changes"
  git -C "$LCT_REMOTE_DIR" pull --ff-only >/dev/null 2>&1 || true
fi

if [ -f "$LCT_CONFIG_FILE" ] && [ "$FORCE" == 0 ]; then
  echo "Using existing config.yaml at $LCT_CONFIG_FILE"
else
  echo "Using config.yaml from remote repository"
  cp "$LCT_REMOTE_DIR/config.yaml" "$LCT_CONFIG_FILE"
fi

echo "Installing package manager dependencies"
lct_log_debug "Installing package manager bundle from ${LCT_REMOTE_DIR}"
_lct_install_gathered_package_bundle "$LCT_REMOTE_DIR"

if [ -d "$SOFTWARE_DIR" ]; then
  echo " $SOFTWARE_DIR already exists"
else
  echo " Creating $SOFTWARE_DIR"
  mkdir -p "$SOFTWARE_DIR"
fi

echo "Applying library configs"
lct_log_debug "Applying ${#CONFIGS[@]} config entries"

for lib in "${CONFIGS[@]}"; do
  if [ -d "$CONFIG_DIR/$lib" ] && [ "$FORCE" == 0 ]; then
    echo "$lib config already exists"
  else
    echo "Applying $lib config"
    rm -rf "$CONFIG_DIR/$lib"
    cp -r "$REMOTE_CONFIGS_DIR/$lib" "$CONFIG_DIR/"
  fi
done

echo "✅ Configs successfully copied"

if ((${#PROJECTS[@]})); then
  echo "Cloning configured projects"
  lct_log_debug "Cloning ${#PROJECTS[@]} projects into ${CODE_DIR}"
  [[ -d "$CODE_DIR" ]] || mkdir -p "$CODE_DIR"

  for project in "${PROJECTS[@]}"; do
    [[ -n "$project" ]] || continue

    if ! project_entry_valid "$project"; then
      echo "❌ ERROR: Skipping invalid project entry '${project}'" >&2
      exit 1
    fi

    repo_name="${project#*/}"
    dest_dir="${CODE_DIR}/${repo_name}"
    if [[ -d "$dest_dir" ]]; then
      echo " - ${project} already present"
      continue
    fi

    clone_url="$(project_clone_url "$project")"
    lct_log_debug "Cloning ${project} from ${clone_url} into ${dest_dir}"
    if ! gum_spinner "Cloning ${project}" git clone --quiet "$clone_url" "$dest_dir"; then
      echo "❌ ERROR: Failed to clone ${project} from ${clone_url}" >&2
      exit 1
    fi
  done

  echo "✅ Projects cloned"
fi

############# plugin installations #############
total_plugins=${#PLUGINS[@]}
loaded=0

plugin_installation
load_plugins

module_installation
lct_log_info "Bootstrap completed successfully"

# ##################################################

echo "✅ Bootstrap complete"
if gum_available; then
  gum_join_vertical \
    "$(gum style --foreground 212 'Add the following to your shell to complete setup:')" \
    "$(gum style --foreground 121 'eval \"$(lct setup)\"')"
else
  echo "Feel free to add  the following to your zshrc file"
  echo 'eval "$(lct setup)"'
fi
