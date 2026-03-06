lct_read_secret_passphrase() {
  local prompt="${1:-Enter password}"
  local passphrase=""

  if [[ -n "${LCT_SECRET_PASSPHRASE:-}" ]]; then
    printf '%s\n' "$LCT_SECRET_PASSPHRASE"
    return 0
  fi

  if gum_available; then
    passphrase="$(gum input --password --prompt "$prompt ")" || return 1
  else
    read -r -s -p "$prompt " passphrase || return 1
    echo
  fi

  printf '%s\n' "$passphrase"
}

lct_secret_relative_path() {
  local input="$1"

  if ! input="$(to_home_tilde_path "$input")"; then
    return 1
  fi

  home_path_to_relative "$input"
}

lct_secret_archive_name() {
  local input="$1"
  local relative encoded

  if ! relative="$(lct_secret_relative_path "$input")"; then
    return 1
  fi

  # Use a collision-resistant, filename-safe encoding (base64url) of the relative path.
  if ! encoded="$(printf '%s' "$relative" | base64 | tr '+/' '-_' | tr -d '=')"; then
    return 1
  fi

  printf '%s.tar.gz.enc\n' "$encoded"
}

lct_encrypt_secret_path() {
  local input="$1"
  local dest_dir="$2"
  local passphrase="$3"
  local relative archive_name expanded tmp_tar dest_file

  if [[ -z "$passphrase" ]]; then
    echo "❌ Encryption password is required" >&2
    return 1
  fi

  if ! relative="$(lct_secret_relative_path "$input")"; then
    echo "❌ Secret path must resolve inside HOME: $input" >&2
    return 1
  fi

  expanded="$(expand_home_path "$input")"
  if [[ ! -e "$expanded" ]]; then
    echo "⚠ Secret path missing, skipping: $input"
    lct_log_warn "Secret path missing, skipping: ${input}"
    return 0
  fi

  archive_name="$(lct_secret_archive_name "$input")" || return 1

  mkdir -p "$dest_dir"

  tmp_tar="$(mktemp "${LCT_CACHE_DIR:-/tmp}/lct-secret.XXXXXX.tar.gz")"
  tar -czf "$tmp_tar" -C "$HOME" -- "$relative"

  dest_file="$dest_dir/$archive_name"
  if ! openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$passphrase" -in "$tmp_tar" -out "$dest_file"; then
    echo "❌ Failed to encrypt secret: $input" >&2
    lct_log_error "Failed to encrypt secret ${input}"
    rm -f "$tmp_tar"
    return 1
  fi

  rm -f "$tmp_tar"
  lct_log_debug "Encrypted secret ${input} -> ${dest_file}"
}

lct_decrypt_secret_archive() {
  local encrypted_file="$1"
  local output_tar="$2"
  local passphrase="$3"

  openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:$passphrase" -in "$encrypted_file" -out "$output_tar"
}
