#!/usr/bin/env bash
set -euo pipefail

error_handler() {
  local exit_code=$? # Capture the exit code of the failed command
  echo "❌ ERROR: Command failed with exit code $exit_code on line $LINENO" >&2
  echo "❌ Failing command: $BASH_COMMAND" >&2
  echo "❌ LCT release failed"
  exit $exit_code # Exit the script with the original error code
}

trap error_handler ERR

echo "Starting LCT Release Process"
release_version="v$(target/build/lct --version)"
read -p "Releasing version: $release_version: (y/n) " -n 1 version_confirm
echo
if [[ "$version_confirm" != "y" ]]; then
  echo "❌ Release aborted by user"
  exit 1
fi

read -p "Version Title (e.g. 'Initial Release'): " version_title
echo

read -p "Version Description: " version_description
echo

echo "Building LCT binary for release"
tar -cJf "lct-$release_version.tar.xz" -C target/build lct
mv "lct-$release_version.tar.xz" "target/release/lct-$release_version.tar.xz"
echo "✅ LCT binary built and compressed"

echo "Creating GitHub release for $release_version"
gh release create "$release_version" "target/release/lct-$release_version.tar.xz" --title "$version_title" --notes "$version_description" --prerelease
echo "✅ GitHub release created successfully"
