if ! git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ ERROR: project remove must be run inside a git repository" >&2
  exit 1
fi

if ! owner_repo="$(project_owner_repo_from_git)"; then
  exit 1
fi

ensure_config_defaults
if PROJECT_ENTRY="$owner_repo" yq -e '((.projects // []) | map(select(. == env(PROJECT_ENTRY)))) | length > 0' "$LCT_CONFIG_FILE" >/dev/null 2>&1; then
  PROJECT_ENTRY="$owner_repo" yq -i '.projects = (.projects // []) | .projects |= map(select(. != env(PROJECT_ENTRY)))' "$LCT_CONFIG_FILE"
  echo "Removed project ${owner_repo}"
else
  echo "Project ${owner_repo} not configured"
fi
