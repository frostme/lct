#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "remove command"

mock_repo_root="$tmpdir/mock-github/example/demo"
rm -rf "$mock_repo_root"
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

project_dir="$tmpdir/remove-project"
mkdir -p "$project_dir"
cat >"$project_dir/LCTFile" <<'EOF'
example/demo = 'v1.0.0'
example/demo
EOF

"${cli}" install -g example/demo >/dev/null
pushd "$project_dir" >/dev/null
"${cli}" install >/dev/null
popd >/dev/null

approve "(cd $project_dir && ${cli} remove example/demo)" "remove_module_local"
approve "cat $project_dir/LCTFile" "remove_module_local_lctfile"
approve "(cd $project_dir && ${cli} remove example/demo)" "remove_module_local_idempotent"
approve "${cli} remove -g example/demo" "remove_module_global"
approve "cat $tmpdir/.local/share/lct/LCTFile" "remove_module_global_lctfile"
approve "${cli} remove -g example/demo" "remove_module_global_idempotent"

manifest_repo_root="$tmpdir/mock-github/whoaa512/hyperfine"
rm -rf "$manifest_repo_root"
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

manifest_project="$tmpdir/project-manifest"
mkdir -p "$manifest_project"
touch "$manifest_project/LCTFile"

pushd "$manifest_project" >/dev/null
"${cli}" install whoaa512/hyperfine >/dev/null
approve "${cli} remove whoaa512/hyperfine" "remove_module_manifest_node"
popd >/dev/null
