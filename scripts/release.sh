#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

build_path="target/build/lct"
release_dir="target/release"
changelog_file="CHANGELOG.md"
release_notes_file="${release_dir}/release-notes.md"
version="$(yq '.version' src/bashly.yml)"
tag="v${version}"

if [[ ! -f "$build_path" ]]; then
  echo "Release build not found at ${build_path}. Run 'just build' before releasing." >&2
  exit 1
fi

if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
  last_tag="$(git describe --tags --abbrev=0 "${tag}^" 2>/dev/null || true)"
else
  last_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
fi

if [[ -n "$last_tag" ]]; then
  commits="$(git log --no-merges --pretty=format:'- %s' "${last_tag}..HEAD")"
else
  commits="$(git log --no-merges --pretty=format:'- %s')"
fi

if [[ -z "$commits" ]]; then
  commits="- No changes found"
fi

changelog_url=""
if [[ -n "$last_tag" ]]; then
  changelog_url="https://github.com/frostme/lct/compare/${last_tag}...${tag}"
fi

mkdir -p "$release_dir"
{
  echo "## What's Changed"
  echo "$commits"
  if [[ -n "$changelog_url" ]]; then
    echo
    echo "**Full Changelog**: ${changelog_url}"
  fi
} >"$release_notes_file"

existing_body=""
if [[ -f "$changelog_file" ]]; then
  if head -n 1 "$changelog_file" | grep -q "^# Changelog"; then
    existing_body="$(tail -n +2 "$changelog_file" | sed '1{/^$/d}')"
  else
    existing_body="$(cat "$changelog_file")"
  fi
fi

{
  echo "# Changelog"
  echo
  echo "## v${version} - $(date +%Y-%m-%d)"
  echo
  echo "### What's Changed"
  echo "$commits"
  if [[ -n "$changelog_url" ]]; then
    echo
    echo "**Full Changelog**: ${changelog_url}"
  fi
  if [[ -n "$existing_body" ]]; then
    echo
    printf "%s\n" "$existing_body"
  fi
} >"$changelog_file"

zip_asset="${release_dir}/${version}.zip"
tar_asset="${release_dir}/${version}.tar.gz"
rm -f "$zip_asset" "$tar_asset"

zip -j "$zip_asset" "$build_path"
tar -czf "$tar_asset" -C "$(dirname "$build_path")" "$(basename "$build_path")"

echo "Release ${tag} assets prepared."
echo "Release notes: ${release_notes_file}"
echo "Assets:"
echo "  - ${zip_asset}"
echo "  - ${tar_asset}"
echo
echo "Publish by pushing the tag and letting the GitHub Action create the release:"
echo "  git tag ${tag}"
echo "  git push origin ${tag}"
