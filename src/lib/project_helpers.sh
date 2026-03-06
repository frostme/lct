project_entry_valid() {
  local entry="$1"
  [[ "$entry" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]
}

project_owner_repo_from_git() {
  local remote_url path owner repo

  if ! remote_url="$(git config --get remote.origin.url 2>/dev/null)"; then
    echo "❌ ERROR: Current directory is not a git repository with an origin remote" >&2
    return 1
  fi

  if [[ -z "$remote_url" ]]; then
    echo "❌ ERROR: Origin remote is not configured for this repository" >&2
    return 1
  fi

  lct_log_debug "Parsing origin remote for project entry: ${remote_url}"
  remote_url="${remote_url%.git}"

  if [[ "$remote_url" =~ ^git@[^:]+:(.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^ssh://[^/]+/(.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^https?://[^/]+/(.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^git://[^/]+/(.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^file://(.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
    path="${path%/}"
    owner="$(basename "$(dirname "$path")")"
    repo="$(basename "$path")"
    if project_entry_valid "${owner}/${repo}"; then
      printf '%s/%s\n' "$owner" "$repo"
      return 0
    fi
    echo "❌ ERROR: Unable to determine OWNER/REPO from origin remote: ${remote_url}" >&2
    return 1
  elif [[ "$remote_url" =~ ^([^/]+/[^/]+)$ ]]; then
    path="${BASH_REMATCH[1]}"
  else
    echo "❌ ERROR: Unable to determine OWNER/REPO from origin remote: ${remote_url}" >&2
    return 1
  fi

  path="${path#/}"
  owner="${path%%/*}"
  repo="${path#*/}"
  repo="${repo%%/*}"

  if project_entry_valid "${owner}/${repo}"; then
    printf '%s/%s\n' "$owner" "$repo"
    return 0
  fi

  echo "❌ ERROR: Origin remote must be in OWNER/REPO format" >&2
  return 1
}

project_clone_base() {
  local base="${LCT_PROJECT_CLONE_BASE:-${LCT_GITHUB_BASE:-}}"
  if [[ -z "$base" ]]; then
    base="git@github.com:"
  fi
  printf '%s\n' "$base"
}

project_clone_url() {
  local entry="$1"
  local base

  base="$(project_clone_base)"
  base="${base%/}"

  if [[ "$base" == git@*:* ]]; then
    printf '%s%s.git\n' "$base" "$entry"
  elif [[ "$base" == git@* && "$base" != *: ]]; then
    printf '%s:%s.git\n' "$base" "$entry"
  else
    printf '%s/%s.git\n' "$base" "$entry"
  fi
}
