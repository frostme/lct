#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "install command"

mock_repo_root="$tmpdir/mock-github/example/demo"
mkdir -p "$mock_repo_root"
git -C "$mock_repo_root" init -q
git -C "$mock_repo_root" config user.email "test@example.com"
git -C "$mock_repo_root" config user.name "Test User"
cat >"$mock_repo_root/demo" <<'EOF'
#!/usr/bin/env bash
echo "demo module"
EOF
chmod +x "$mock_repo_root/demo"
git -C "$mock_repo_root" add demo
git -C "$mock_repo_root" commit -q -m "initial"
git -C "$mock_repo_root" tag v1.0.0
cat >"$mock_repo_root/demo" <<'EOF'
#!/usr/bin/env bash
echo "demo module v1.1"
EOF
git -C "$mock_repo_root" add demo
git -C "$mock_repo_root" commit -q -m "second"
git -C "$mock_repo_root" tag v1.1.0

approve "${cli} install -g example/demo" "install_module"
approve "${cli} install -g example/demo" "install_module_idempotent"
approve "cat $tmpdir/.local/share/lct/LCTFile" "install_module_global_lctfile"

semver_repo_root="$tmpdir/mock-github/fsaintjacques/semver-tool"
mkdir -p "$semver_repo_root/src" "$semver_repo_root/test"
git -C "$semver_repo_root" init -q
git -C "$semver_repo_root" config user.email "test@example.com"
git -C "$semver_repo_root" config user.name "Test User"
cat >"$semver_repo_root/src/semver" <<'EOF'
#!/usr/bin/env bash
echo "semver"
EOF
chmod +x "$semver_repo_root/src/semver"
cat >"$semver_repo_root/test/documentation-test" <<'EOF'
#!/usr/bin/env bash
echo "docs test"
EOF
chmod +x "$semver_repo_root/test/documentation-test"
git -C "$semver_repo_root" add src/semver test/documentation-test
git -C "$semver_repo_root" commit -q -m "initial"

approve "${cli} install -g fsaintjacques/semver-tool" "install_module_semver"

gum_repo_root="$tmpdir/mock-github/charmbracelet/gum"
mkdir -p "$gum_repo_root/test"
git -C "$gum_repo_root" init -q
git -C "$gum_repo_root" config user.email "test@example.com"
git -C "$gum_repo_root" config user.name "Test User"
cat >"$gum_repo_root/gum.sh" <<'EOF'
#!/usr/bin/env bash
echo "gum"
EOF
chmod +x "$gum_repo_root/gum.sh"
cat >"$gum_repo_root/test/test.sh" <<'EOF'
#!/usr/bin/env bash
echo "test"
EOF
chmod +x "$gum_repo_root/test/test.sh"
git -C "$gum_repo_root" add gum.sh test/test.sh
git -C "$gum_repo_root" commit -q -m "initial"

approve "${cli} install -g charmbracelet/gum" "install_module_gum"

ambiguous_repo_root="$tmpdir/mock-github/example/ambiguous"
mkdir -p "$ambiguous_repo_root/docs" "$ambiguous_repo_root/test"
git -C "$ambiguous_repo_root" init -q
git -C "$ambiguous_repo_root" config user.email "test@example.com"
git -C "$ambiguous_repo_root" config user.name "Test User"
cat >"$ambiguous_repo_root/docs/run.sh" <<'EOF'
#!/usr/bin/env bash
echo "docs"
EOF
chmod +x "$ambiguous_repo_root/docs/run.sh"
cat >"$ambiguous_repo_root/test/helper.sh" <<'EOF'
#!/usr/bin/env bash
echo "test"
EOF
chmod +x "$ambiguous_repo_root/test/helper.sh"
git -C "$ambiguous_repo_root" add docs/run.sh test/helper.sh
git -C "$ambiguous_repo_root" commit -q -m "initial"

approve "${cli} install -g example/ambiguous" "install_module_ambiguous"

make_repo_root="$tmpdir/mock-github/example/makepkg"
mkdir -p "$make_repo_root"
git -C "$make_repo_root" init -q
git -C "$make_repo_root" config user.email "test@example.com"
git -C "$make_repo_root" config user.name "Test User"
cat >"$make_repo_root/main.sh" <<'EOF'
#!/usr/bin/env bash
echo "make module"
EOF
chmod +x "$make_repo_root/main.sh"
cat >"$make_repo_root/Makefile" <<'EOF'
all:
	@mkdir -p bin
	@cp main.sh bin/make-tool

install: all
	@mkdir -p $(PREFIX)/bin
	@cp bin/make-tool $(PREFIX)/bin/make-tool
EOF
git -C "$make_repo_root" add main.sh Makefile
git -C "$make_repo_root" commit -q -m "initial"

project_make="$tmpdir/project-make"
mkdir -p "$project_make"
touch "$project_make/LCTFile"

pushd "$project_make" >/dev/null
approve "${cli} install example/makepkg" "install_module_make"
popd >/dev/null

manifest_repo_root="$tmpdir/mock-github/whoaa512/hyperfine"
mkdir -p "$manifest_repo_root"
git -C "$manifest_repo_root" init -q
git -C "$manifest_repo_root" config user.email "test@example.com"
git -C "$manifest_repo_root" config user.name "Test User"
cat >"$manifest_repo_root/package.json" <<'EOF'
{
  "name": "hyperfine",
  "version": "1.0.0"
}
EOF
git -C "$manifest_repo_root" add package.json
git -C "$manifest_repo_root" commit -q -m "initial"

manifest_project="$tmpdir/project-manifest-install"
mkdir -p "$manifest_project"
touch "$manifest_project/LCTFile"

pushd "$manifest_project" >/dev/null
approve "${cli} install whoaa512/hyperfine" "install_module_manifest_node"
popd >/dev/null

approve "${cli} install -g" "install_without_modules"

describe "install via LCTFile"
project_dir="$tmpdir/project"
mkdir -p "$project_dir"
cat >"$project_dir/LCTFile" <<'EOF'
example/demo = 'v1.0.0'
example/demo
EOF

pushd "$project_dir" >/dev/null
approve "${cli} install" "install_from_lctfile"
approve "${cli} install" "install_from_lctfile_idempotent"
approve "${cli} install example/demo" "install_module_local"
approve "cat LCTFile" "install_module_local_lctfile"
popd >/dev/null
