remote_path=${args[file]}
source_path=${args[source]}

normalize_home_relative_path() {
  local value="$1"

  if [[ "$value" == "$HOME/"* ]]; then
    printf '%s\n' "${value#"$HOME/"}"
    return 0
  fi

  if [[ "$value" == "~/"* ]]; then
    printf '%s\n' "${value#~/}"
    return 0
  fi

  if [[ "$value" == /* ]]; then
    return 1
  fi

  printf '%s\n' "$value"
}

validate_relative_path() {
  local path="$1"
  local IFS='/'
  local segment

  # Split the path on '/' and ensure no segment is '.' or '..'
  read -ra segments <<< "$path"
  for segment in "${segments[@]}"; do
    if [[ "$segment" == "." || "$segment" == ".." ]]; then
      return 1
    fi
  done

  return 0
}

if ! remote_path=$(normalize_home_relative_path "$remote_path"); then
  echo "❌ ERROR: File destination must be relative to HOME or use ~/" >&2
  exit 1
fi

if ! validate_relative_path "$remote_path"; then
  echo "❌ ERROR: File destination must not contain '.' or '..' path segments" >&2
  exit 1
fi

if ! source_path=$(normalize_home_relative_path "$source_path"); then
  echo "❌ ERROR: File source must be relative to HOME or use ~/" >&2
  exit 1
fi

if ! validate_relative_path "$source_path"; then
  echo "❌ ERROR: File source must not contain '.' or '..' path segments" >&2
  exit 1
fi
if [[ -z "$remote_path" || "$remote_path" == "." ]]; then
  echo "❌ ERROR: File destination is required" >&2
  exit 1
fi

if [[ -z "$source_path" || "$source_path" == "." ]]; then
  echo "❌ ERROR: File source is required" >&2
  exit 1
fi

ensure_config_defaults
REMOTE_PATH="$remote_path" SOURCE_PATH="$source_path" yq -i '.other = (.other // {}) | .other[env(REMOTE_PATH)] = env(SOURCE_PATH)' "$LCT_CONFIG_FILE"
