#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"
source "$(dirname "$0")/../src/lib/package_manager_registry.sh"
source "$(dirname "$0")/../src/lib/package_manager.sh"

describe "package manager registry"

assert_equal() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  if [[ "$actual" == "$expected" ]]; then
    pass "$description"
  else
    fail "$description (expected '$expected', got '$actual')"
  fi
}

it "validates the complete registry"
_lct_validate_package_manager_registry
pass "registry is valid"

it "rejects duplicate manager names"
(
  _lct_package_manager_registry() {
    cat <<'EOF'
demo|system|none|demo|demo|demo|unsupported|unsupported|unsupported
demo|runtime|none|demo|demo|demo|unsupported|unsupported|unsupported
EOF
  }

  if _lct_validate_package_manager_registry; then
    fail "duplicate manager names were accepted"
  else
    pass "duplicate manager names are rejected"
  fi
)

it "rejects invalid manager categories"
(
  _lct_package_manager_registry() {
    cat <<'EOF'
demo|unknown|none|demo|demo|demo|unsupported|unsupported|unsupported
EOF
  }

  if _lct_validate_package_manager_registry; then
    fail "invalid manager category was accepted"
  else
    pass "invalid manager category is rejected"
  fi
)

it "rejects unknown manager dependencies"
(
  _lct_package_manager_registry() {
    cat <<'EOF'
demo|language|manager:missing|demo|demo|demo|unsupported|unsupported|unsupported
EOF
  }

  if _lct_validate_package_manager_registry; then
    fail "unknown manager dependency was accepted"
  else
    pass "unknown manager dependency is rejected"
  fi
)

it "classifies required managers"
assert_equal "system" "$(_lct_package_manager_get brew category)" "brew is a system manager"
assert_equal "system" "$(_lct_package_manager_get apt category)" "apt is a system manager"
assert_equal "runtime" "$(_lct_package_manager_get mise category)" "mise is a runtime manager"
for manager in pnpm cargo pip uv; do
  assert_equal "language" "$(_lct_package_manager_get "$manager" category)" "$manager is a language manager"
done

it "represents runtime dependencies"
assert_equal "runtime:node" "$(_lct_package_manager_get pnpm dependencies)" "pnpm depends on Node"
assert_equal "runtime:rust" "$(_lct_package_manager_get cargo dependencies)" "cargo depends on Rust"
assert_equal "runtime:python" "$(_lct_package_manager_get pip dependencies)" "pip depends on Python"

it "represents supported and unsupported package bundle operations"
assert_equal "pip" "$(_lct_package_manager_get pip export_handler)" "pip export is supported"
assert_equal "pip" "$(_lct_package_manager_get pip restore_handler)" "pip restore is supported"
for manager in pnpm cargo uv; do
  assert_equal "unsupported" "$(_lct_package_manager_get "$manager" export_handler)" "$manager export is unsupported"
  assert_equal "unsupported" "$(_lct_package_manager_get "$manager" restore_handler)" "$manager restore is unsupported"
done

it "registers every package manager with an install handler"
expected_managers="apt
asdf
aur
brew
bun
cargo
cargo-binstall
composer
dnf
flox
gem
go
mise
nix
npm
pacman
pip
pkg
pnpm
scoop
uv
winget
yarn
yum
zypper"
actual_managers="$(_lct_package_manager_names | sort)"
assert_equal "$expected_managers" "$actual_managers" "all existing managers are registered"

while IFS= read -r manager; do
  [[ -n "$manager" ]] || continue
  if [[ "$(_lct_package_manager_get "$manager" install_handler)" == "unsupported" ]]; then
    fail "$manager has no install handler"
  fi
done < <(_lct_package_manager_names)
pass "all registered managers have install handlers"

it "rejects unknown managers and fields"
if _lct_package_manager_known unknown; then
  fail "unknown manager was accepted"
else
  pass "unknown manager is rejected"
fi

if _lct_package_manager_get brew unknown_field >/dev/null 2>&1; then
  fail "unknown field was accepted"
else
  pass "unknown field is rejected"
fi

it "preserves the existing bundle manager set and filenames"
expected_bundle_managers="brew
pip
apt
dnf
yum
zypper
pacman
aur
pkg
winget
mise
nix"
assert_equal "$expected_bundle_managers" "$(_lct_package_bundle_managers)" "bundle manager discovery is unchanged"
assert_equal "Brewfile" "$(_lct_package_bundle_filename brew)" "brew bundle filename is unchanged"
assert_equal "requirements.txt" "$(_lct_package_bundle_filename pip)" "pip bundle filename is unchanged"
assert_equal "mise-packages.txt" "$(_lct_package_bundle_filename mise)" "mise bundle filename is unchanged"

it "drives bundle discovery from registry metadata"
(
  _lct_package_manager_registry() {
    cat <<'EOF'
demo|system|none|demo|demo|demo|demo|demo|demo-bundle.txt
future|language|runtime:demo|future|future|future|unsupported|unsupported|unsupported
EOF
  }

  assert_equal "demo-bundle.txt" "$(_lct_package_bundle_filename demo)" "bundle filename comes from the registry"
  assert_equal "demo" "$(_lct_package_bundle_managers)" "only bundle-capable registry managers are discovered"
)

it "dispatches package operations through registry handlers"
(
  _lct_package_manager_registry() {
    cat <<'EOF'
demo|system|none|brew|brew|brew|unsupported|unsupported|unsupported
EOF
  }
  brew() {
    printf 'brew %s\n' "$*"
  }
  LCT_SHARE_DIR="$tmpdir/registry-share"
  LCT_BREW_FILE="$LCT_SHARE_DIR/Brewfile"
  mkdir -p "$LCT_SHARE_DIR"

  expected_output="brew install ripgrep
brew bundle add ripgrep --file=$LCT_BREW_FILE"
  actual_output="$(_lct_install_library demo ripgrep)"
  assert_equal "$expected_output" "$actual_output" "install handler comes from the registry"
)

it "dispatches bundle operations through registry handlers"
(
  _lct_package_manager_registry() {
    cat <<'EOF'
demo|system|none|demo|demo|demo|brew|apt|demo-bundle.txt
EOF
  }
  brew() {
    printf 'brew %s\n' "$*" >>"$tmpdir/registry-bundle-calls"
  }
  apt-get() {
    printf 'apt-get %s\n' "$*"
  }
  bundle_file="$tmpdir/demo-bundle.txt"
  printf 'ripgrep\nfd-find\n' >"$bundle_file"

  _lct_dump_package_bundle demo "$bundle_file"
  assert_equal "brew bundle dump --describe --force --file=$bundle_file" "$(cat "$tmpdir/registry-bundle-calls")" "export handler comes from the registry"
  assert_equal "apt-get install -y ripgrep fd-find" "$(_lct_install_package_bundle_from_file demo "$bundle_file")" "restore handler comes from the registry"
)
