run_init_if_needed

FORCE=${args[--force]:-0}
lct_log_debug "gather command started (force=${FORCE})"
GATHER_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REMOTE_CONFIGS_DIR="$LCT_REMOTE_DIR/configs"
REMOTE_DOTFILES_DIR="$LCT_REMOTE_DIR/dotfiles"
REMOTE_OTHER_DIR="$LCT_REMOTE_DIR/other"
REMOTE_SECRETS_DIR="$LCT_REMOTE_SECRETS_DIR"
LCT_FILES=("$LCT_BREW_FILE" "$LCT_CONFIG_FILE")
SECRET_GREP_PATTERN="api[_-]?key|auth[_-]?token|bearer|secret|password|authorization|private key|ssh-rsa|BEGIN [A-Z ]*PRIVATE KEY"

copy_entry() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ -e "$src" ]]; then
    lct_log_debug "Copying ${label}: ${src} -> ${dest}"
    mkdir -p "$(dirname "$dest")"
    cp -R "$src" "$dest"
  else
    lct_log_warn "Missing ${label}, skipping: ${src}"
    echo "⚠ Skipping missing ${label}: $src"
  fi
}

find_secret_hits() {
  mapfile -t SECRET_HITS < <(grep -R -n -I -E "$SECRET_GREP_PATTERN" "$LCT_REMOTE_DIR" --exclude-dir=.git 2>/dev/null || true)
  if ((${#SECRET_HITS[@]})); then
    local filtered_hits=()
    local match_file
    for match in "${SECRET_HITS[@]}"; do
      IFS=: read -r match_file _ <<<"$match"
      if [[ "$match_file" == "$LCT_REMOTE_DIR/config.yaml" ]]; then
        continue
      fi
      filtered_hits+=("$match")
    done
    SECRET_HITS=("${filtered_hits[@]}")
  fi
}

scrub_secret_files() {
  declare -A files_to_scrub=()

  for match in "${SECRET_HITS[@]}"; do
    IFS=: read -r file _ <<<"$match"
    files_to_scrub["$file"]=1
  done

  for file in "${!files_to_scrub[@]}"; do
    rm -rf "$file"
    echo "🧹 Removed $file from gathered output"
  done
}

handle_secret_hits() {
  find_secret_hits

  if ((${#SECRET_HITS[@]} == 0)); then
    lct_log_debug "No potential secret hits detected in gathered files"
    return
  fi

  echo "⚠ Potential secrets detected in gathered files:"
  printf '  %s\n' "${SECRET_HITS[@]}"

  local action="${LCT_GATHER_SECRET_ACTION:-}"

  case "$action" in
  "")
    if gum_confirm_prompt "Continue and commit these files as-is?"; then
      echo "Proceeding with gather despite potential secrets"
      return
    fi

    if gum_confirm_prompt "Scrub detected files from gather and continue?"; then
      scrub_secret_files
      find_secret_hits
      if ((${#SECRET_HITS[@]})); then
        lct_log_error "Gather scrub failed to remove all secret hits"
        echo "❌ Secrets still detected after scrubbing; aborting gather" >&2
        exit 1
      fi
      return
    fi

    echo "❌ Gather aborted to avoid committing secrets"
    lct_log_error "Gather aborted by user during secret review"
    exit 1
    ;;
  continue)
    echo "Proceeding with gather despite potential secrets (LCT_GATHER_SECRET_ACTION=continue)"
    lct_log_warn "Gather continuing with detected secret hits due to configured action"
    ;;
  scrub)
    lct_log_warn "Gather scrubbing files with potential secret hits"
    scrub_secret_files
    ;;
  abort)
    echo "❌ Gather aborted to avoid committing secrets"
    lct_log_error "Gather aborted due to LCT_GATHER_SECRET_ACTION=abort"
    exit 1
    ;;
  *)
    echo "❌ Invalid LCT_GATHER_SECRET_ACTION value: $action (expected continue, scrub, abort)" >&2
    lct_log_error "Invalid LCT_GATHER_SECRET_ACTION value: ${action}"
    exit 1
    ;;
  esac
}

gather_secrets() {
  if ((${#SECRETS[@]} == 0)); then
    lct_log_debug "No secrets configured; skipping secret encryption"
    rm -rf "$REMOTE_SECRETS_DIR"
    return
  fi

  if ! command -v openssl >/dev/null 2>&1; then
    echo "❌ openssl is required to encrypt secrets" >&2
    lct_log_error "openssl missing; cannot encrypt secrets"
    exit 1
  fi

  local passphrase
  if ! passphrase="$(lct_read_secret_passphrase "Enter password to encrypt secrets (session only):")"; then
    echo "❌ Failed to read encryption password" >&2
    exit 1
  fi

  if [[ -z "$passphrase" ]]; then
    echo "❌ Encryption password cannot be empty" >&2
    exit 1
  fi

  rm -rf "$REMOTE_SECRETS_DIR"
  mkdir -p "$REMOTE_SECRETS_DIR"

  echo "Encrypting configured secrets"
  for secret_path in "${SECRETS[@]}"; do
    echo "Encrypting $secret_path"
    if ! lct_encrypt_secret_path "$secret_path" "$REMOTE_SECRETS_DIR" "$passphrase"; then
      echo "❌ Failed to encrypt configured secret: $secret_path" >&2
      exit 1
    fi
  done
  echo "✅ Secrets encrypted"
}

gum_title "Gathering configs into remote repository"


rm -rf "$REMOTE_CONFIGS_DIR" "$REMOTE_DOTFILES_DIR" "$REMOTE_OTHER_DIR" "$REMOTE_SECRETS_DIR"
mkdir -p "$REMOTE_CONFIGS_DIR" "$REMOTE_DOTFILES_DIR" "$REMOTE_OTHER_DIR"

echo "Gathering LCT files"
for file in "${LCT_FILES[@]}"; do
  echo "Copying $(basename "$file")"
  copy_entry "$file" "$LCT_REMOTE_DIR/$(basename "$file")" "LCT file"
done

while IFS= read -r bundle_file; do
  [[ -n "$bundle_file" ]] || continue
  rm -f "$LCT_REMOTE_DIR/$bundle_file"
done < <(_lct_package_bundle_known_files)

echo "Gathering package manager bundle"
_lct_gather_package_bundle "$LCT_REMOTE_DIR"

echo "Gathering library configs"
for lib in "${CONFIGS[@]}"; do
  src_path="$CONFIG_DIR/$lib"
  dest_path="$REMOTE_CONFIGS_DIR/$lib"
  echo "Copying $lib config"
  copy_entry "$src_path" "$dest_path" "config"
done
echo "✅ Configs successfully gathered"

echo "Gathering dotfiles"
for file in "${DOTFILES[@]}"; do
  src_path="$(expand_home_path "$file")"
  dest_path="$REMOTE_DOTFILES_DIR/$(home_path_to_relative "$file")"
  echo "Copying $file"
  copy_entry "$src_path" "$dest_path" "dotfile"
done
echo "✅ Dotfiles successfully gathered"

echo "Gathering other files"
for file in "${OTHERFILES[@]}"; do
  src_file="$(expand_home_path "$file")"
  dest_file="$REMOTE_OTHER_DIR/$(home_path_to_relative "$file")"
  echo "Copying $src_file to $dest_file"
  copy_entry "$src_file" "$dest_file" "other file"
done
echo "✅ Other files successfully gathered"

rm -f "$LCT_REMOTE_DIR/lct.yaml"

gather_secrets

handle_secret_hits

git -C "$LCT_REMOTE_DIR" add .
git -C "$LCT_REMOTE_DIR" commit -m "Gather configs ${GATHER_TIMESTAMP}" || echo "No changes to commit"
if git -C "$LCT_REMOTE_DIR" remote get-url origin >/dev/null 2>&1; then
  git -C "$LCT_REMOTE_DIR" push origin main || echo "Failed to push to remote 'origin', skipping push (see git error above)"
else
  echo "No remote repository configured, skipping push"
fi
lct_log_info "Gather completed (timestamp=${GATHER_TIMESTAMP})"

if gum_available; then
  gum_join_vertical \
    "$(gum style --foreground 121 "✅ Config gather completed successfully")" \
    "$(gum style --foreground 244 "Stored in repository: $LCT_REMOTE_DIR")"
else
  echo "✅ Config gather completed successfully"
fi
