repo="frostme/lct"

get_latest_version() {
  local tag

  tag="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" |
    awk -F '"' '/"tag_name":/ {print $4; exit}')"

  if [[ -z "$tag" ]]; then
    echo "❌ ERROR: Unable to determine the latest lct release." >&2
    return 1
  fi

  printf '%s\n' "${tag#v}"
}

current_version="${version:-unknown}"
latest_version="$(get_latest_version)" || exit 1

if [[ "$current_version" == "$latest_version" ]]; then
  echo "lct is already up to date (${current_version})."
  exit 0
fi

if ! gum_confirm_prompt "Update from ${current_version} to ${latest_version}?"; then
  echo "Update canceled."
  exit 0
fi

if [[ "$current_version" == "unknown" ]]; then
  echo "Updating lct to ${latest_version}..."
else
  echo "Updating lct from ${current_version} to ${latest_version}..."
fi

if curl -fsSL https://frostme.github.io/lct/install.sh | bash; then
  echo "✅ Updated lct to ${latest_version}."
else
  echo "❌ ERROR: Self-update failed." >&2
  exit 1
fi
