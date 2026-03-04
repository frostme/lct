if ! git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ ERROR: project add must be run inside a git repository" >&2
  exit 1
fi

if ! owner_repo="$(project_owner_repo_from_git)"; then
  exit 1
fi

ensure_config_defaults

if PROJECT_ENTRY="$owner_repo" yq -e '((.projects // []) | map(select(. == env(PROJECT_ENTRY)))) | length > 0' "$LCT_CONFIG_FILE" >/dev/null 2>&1; then
  echo "Project ${owner_repo} already configured"
  exit 0
fi

append_unique "projects" "$owner_repo"
echo "Added project ${owner_repo}"
