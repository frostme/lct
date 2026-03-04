#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASHLY_FILE="${ROOT_DIR}/src/bashly.yml"

log() {
  echo "[unrelease] $*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

ensure_repo_state() {
  local branch

  branch="$(git -C "${ROOT_DIR}" branch --show-current)"
  if [[ "${branch}" != "main" ]]; then
    log "This script only runs on branch 'main' (current: ${branch})."
    exit 1
  fi

  if [[ -n "$(git -C "${ROOT_DIR}" status --porcelain)" ]]; then
    log "Working tree must be clean before running this script."
    exit 1
  fi
}

select_release() {
  local -a release_rows release_labels
  local row tag name selected

  mapfile -t release_rows < <(
    gh release list --limit 100 --json tagName,name --jq '.[] | "\(.tagName)\t\(.name // "")"'
  )

  if [[ "${#release_rows[@]}" -eq 0 ]]; then
    log "No releases found."
    exit 1
  fi

  for row in "${release_rows[@]}"; do
    IFS=$'\t' read -r tag name <<<"${row}"
    if [[ -n "${name}" ]]; then
      release_labels+=("${tag} - ${name}")
    else
      release_labels+=("${tag}")
    fi
  done

  selected="$(
    printf '%s\n' "${release_labels[@]}" |
      gum choose --header "Select release to delete"
  )"

  for row in "${release_rows[@]}"; do
    IFS=$'\t' read -r tag name <<<"${row}"
    if [[ -n "${name}" && "${selected}" == "${tag} - ${name}" ]]; then
      RELEASE_TAG="${tag}"
      RELEASE_NAME="${name}"
      return 0
    fi
    if [[ -z "${name}" && "${selected}" == "${tag}" ]]; then
      RELEASE_TAG="${tag}"
      RELEASE_NAME=""
      return 0
    fi
  done

  log "Failed to resolve selected release."
  exit 1
}

prompt_new_version() {
  local current_version default_version input_version

  current_version="$(yq e -r '.version' "${BASHLY_FILE}")"
  default_version="${RELEASE_TAG#v}"

  input_version="$(gum input \
    --prompt "Set src/bashly.yml version to: " \
    --value "${default_version}")"

  if [[ -z "${input_version}" ]]; then
    log "Version cannot be empty."
    exit 1
  fi

  if [[ "${input_version}" == "${current_version}" ]]; then
    log "Version is unchanged (${current_version}). Pick a different version."
    exit 1
  fi

  NEW_VERSION="${input_version}"
  CURRENT_VERSION="${current_version}"
}

confirm_action() {
  echo
  echo "Release deletion plan:"
  echo "  Release: ${RELEASE_NAME:-<no name>}"
  echo "  Tag:     ${RELEASE_TAG}"
  echo "  Version: ${CURRENT_VERSION} -> ${NEW_VERSION} in src/bashly.yml"
  echo
  echo "This will delete the tag and release permanently."
  echo

  if ! gum confirm "Proceed with deletion?"; then
    log "Cancelled."
    exit 0
  fi
}

delete_local_tag_if_present() {
  if git -C "${ROOT_DIR}" rev-parse -q --verify "refs/tags/${RELEASE_TAG}" >/dev/null; then
    git -C "${ROOT_DIR}" tag -d "${RELEASE_TAG}" >/dev/null
    return
  fi

  log "Local tag '${RELEASE_TAG}' not found; continuing."
}

main() {
  require_cmd gh
  require_cmd gum
  require_cmd yq
  require_cmd git

  ensure_repo_state
  select_release
  prompt_new_version
  confirm_action

  # Keep this exact order to safely undo the release.
  # delete_local_tag_if_present
  # git -C "${ROOT_DIR}" push --quiet --delete origin "${RELEASE_TAG}"
  # yq -i ".version = \"${NEW_VERSION}\"" "${BASHLY_FILE}"
  # git -C "${ROOT_DIR}" commit --quiet -am "Undo release ${RELEASE_TAG}"
  # git -C "${ROOT_DIR}" push --quiet origin main &>/dev/null
  # gh release delete "${RELEASE_TAG}" --yes

  log "Deleted release ${RELEASE_TAG} and updated version to ${NEW_VERSION}."
}

main "$@"
