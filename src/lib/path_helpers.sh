expand_home_path() {
  local value="$1"

  if [[ "$value" == "~/"* ]]; then
    printf '%s\n' "$HOME/${value#\~/}"
    return 0
  fi

  if [[ "$value" == "$HOME/"* || "$value" == /* ]]; then
    printf '%s\n' "$value"
    return 0
  fi

  printf '%s\n' "$HOME/$value"
}

canonicalize_path() {
  local input="$1"
  local expanded dir base canonical_dir

  if [[ "$input" == "~/"* ]]; then
    expanded="$HOME/${input#\~/}"
  elif [[ "$input" == /* ]]; then
    expanded="$input"
  else
    expanded="$PWD/$input"
  fi

  dir="$(dirname "$expanded")"
  base="$(basename "$expanded")"

  if ! canonical_dir="$(cd "$dir" 2>/dev/null && pwd -P)"; then
    return 1
  fi

  printf '%s/%s\n' "$canonical_dir" "$base"
}

to_home_tilde_path() {
  local input="$1"
  local canonical home_canonical

  if ! canonical="$(canonicalize_path "$input")"; then
    return 1
  fi

  home_canonical="$(cd "$HOME" 2>/dev/null && pwd -P)"
  [[ -n "$home_canonical" ]] || home_canonical="$HOME"

  if [[ "$canonical" == "$home_canonical" ]]; then
    printf '~\n'
    return 0
  fi

  if [[ "$canonical" != "$home_canonical/"* ]]; then
    return 1
  fi

  printf '~/%s\n' "${canonical#"$home_canonical/"}"
}

home_path_to_relative() {
  local value="$1"

  if [[ "$value" == "~/"* ]]; then
    printf '%s\n' "${value#\~/}"
    return 0
  fi

  if [[ "$value" == "$HOME/"* ]]; then
    printf '%s\n' "${value#"$HOME/"}"
    return 0
  fi

  printf '%s\n' "$value"
}

config_name_from_path() {
  local input="$1"
  local allow_simple="${2:-1}"
  local canonical config_dir_canonical remainder

  if [[ "$allow_simple" == "1" && "$input" != */* && "$input" != "~"* ]]; then
    printf '%s\n' "$input"
    return 0
  fi

  if ! canonical="$(canonicalize_path "$input")"; then
    return 1
  fi

  config_dir_canonical="$(cd "$CONFIG_DIR" 2>/dev/null && pwd -P)"

  if [[ "$canonical" != "$config_dir_canonical/"* ]]; then
    return 1
  fi

  remainder="${canonical#"$config_dir_canonical/"}"
  printf '%s\n' "${remainder%%/*}"
}

is_home_dotfile_path() {
  local input="$1"
  local canonical home_canonical
  local base parent

  if ! canonical="$(canonicalize_path "$input")"; then
    return 1
  fi

  home_canonical="$(cd "$HOME" 2>/dev/null && pwd -P)"
  [[ -n "$home_canonical" ]] || home_canonical="$HOME"

  base="$(basename "$canonical")"
  parent="$(dirname "$canonical")"

  [[ "$parent" == "$home_canonical" ]] || return 1
  [[ "$base" == .* ]] || return 1
  [[ "$base" != ".config" ]] || return 1
}

config_name_to_path() {
  local config_name="$1"
  local config_path="$CONFIG_DIR/$config_name"
  local tilde_path

  if tilde_path="$(to_home_tilde_path "$config_path" 2>/dev/null)"; then
    printf '%s\n' "$tilde_path"
    return 0
  fi

  printf '%s\n' "$config_path"
}
