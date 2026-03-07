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

restore_secrets() {
  if ((${#SECRETS[@]} == 0)); then
    lct_log_debug "No secrets configured; skipping secret restore"
    return
  fi

  if [[ ! -d "$LCT_REMOTE_SECRETS_DIR" ]]; then
    echo "ℹ No encrypted secrets found in remote repository, skipping secrets restore"
    lct_log_warn "Secrets configured but ${LCT_REMOTE_SECRETS_DIR} is missing"
    return
  fi

  local has_encrypted_archives=0
  local archive_name
  for secret_path in "${SECRETS[@]}"; do
    archive_name="$(lct_secret_archive_name "$secret_path")" || {
      lct_log_warn "Invalid secret path during secrets availability check: ${secret_path}"
      continue
    }
    if [[ -f "$LCT_REMOTE_SECRETS_DIR/$archive_name" ]]; then
      has_encrypted_archives=1
      break
    fi
  done

  if (( has_encrypted_archives == 0 )); then
    echo "ℹ No encrypted secrets archives found in remote repository, skipping secrets restore"
    lct_log_info "Secrets configured but no encrypted archives present in ${LCT_REMOTE_SECRETS_DIR}"
    return
  fi
  if ! command -v openssl >/dev/null 2>&1; then
    echo "❌ openssl is required to decrypt secrets" >&2
    lct_log_error "openssl missing; cannot decrypt secrets"
    exit 1
  fi

  local passphrase
  if ! passphrase="$(lct_read_secret_passphrase "Enter password to decrypt secrets:")"; then
    echo "❌ Failed to read decryption password" >&2
    exit 1
  fi

  if [[ -z "$passphrase" ]]; then
    echo "❌ Decryption password cannot be empty" >&2
    exit 1
  fi

  echo "Restoring secrets"
  for secret_path in "${SECRETS[@]}"; do
    local archive_name dest_path tmp_tar
    archive_name="$(lct_secret_archive_name "$secret_path")" || {
      echo "⚠ Skipping invalid secret path: $secret_path"
      lct_log_warn "Invalid secret path: ${secret_path}"
      continue
    }

    dest_path="$(expand_home_path "$secret_path")"
    if [[ -e "$dest_path" ]]; then
      echo "Skipping existing secret: $secret_path"
      continue
    fi

    if [[ ! -f "$LCT_REMOTE_SECRETS_DIR/$archive_name" ]]; then
      echo "⚠ Encrypted secret not found for $secret_path, skipping"
      lct_log_warn "Encrypted secret missing for ${secret_path}"
      continue
    fi

    tmp_tar="$(mktemp "${LCT_CACHE_DIR:-/tmp}/lct-secret.XXXXXX.tar.gz")"
    if ! lct_decrypt_secret_archive "$LCT_REMOTE_SECRETS_DIR/$archive_name" "$tmp_tar" "$passphrase"; then
      echo "❌ Failed to decrypt secret: $secret_path" >&2
      rm -f "$tmp_tar"
      exit 1
    fi

    # Validate archive contents before extraction to prevent path traversal
    local archive_entries safe_archive entry
    if ! archive_entries="$(tar -tzf "$tmp_tar")"; then
      echo "❌ Failed to inspect decrypted secret archive for $secret_path" >&2
      rm -f "$tmp_tar"
      exit 1
    fi

    safe_archive=1
    while IFS= read -r entry; do
      # Skip empty lines
      [[ -z "$entry" ]] && continue
      case "$entry" in
        /*|../*|*/../*|*/..|..)
          safe_archive=0
          ;;
      esac
      (( safe_archive )) || break
    done <<< "$archive_entries"

    if (( ! safe_archive )); then
      echo "❌ Unsafe paths detected in decrypted secret archive for $secret_path; aborting restore" >&2
      rm -f "$tmp_tar"
      exit 1
    fi
    tar -xzf "$tmp_tar" -C "$HOME" --keep-old-files
    rm -f "$tmp_tar"
    echo "Restored $secret_path"
  done
}
if ((${#PROJECTS[@]})); then
  echo "Cloning configured projects"
  lct_log_debug "Cloning ${#PROJECTS[@]} projects into ${CODE_DIR}"
  [[ -d "$CODE_DIR" ]] || mkdir -p "$CODE_DIR"

  for project in "${PROJECTS[@]}"; do
    [[ -n "$project" ]] || continue

    if ! project_entry_valid "$project"; then
      echo "❌ ERROR: Invalid project entry '${project}'. Aborting bootstrap." >&2
      exit 1
    fi

    repo_name="${project#*/}"
    dest_dir="${CODE_DIR}/${repo_name}"
    if [[ -e "$dest_dir" && ! -d "$dest_dir" ]]; then
      echo "❌ ERROR: Destination path ${dest_dir} exists and is not a directory; cannot clone ${project}" >&2
      exit 1
    elif [[ -d "$dest_dir" ]]; then
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
restore_secrets
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
