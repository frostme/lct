#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "list command"

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

it "lists globally installed modules"
"${cli}" install -g example/demo >/dev/null
approve "${cli} list -g" "list_global_modules"

it "lists project modules"
project_dir="$tmpdir/project"
mkdir -p "$project_dir"
cat >"$project_dir/LCTFile" <<'EOF'
example/demo
EOF

pushd "$project_dir" >/dev/null
"${cli}" install >/dev/null
approve "${cli} list" "list_local_modules"
popd >/dev/null
