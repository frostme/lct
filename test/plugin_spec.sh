#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "plugin command"

mock_plugin_repo="$tmpdir/mock-github/example/lct-plugins"
mkdir -p "$mock_plugin_repo/plugins/demo"
git -C "$mock_plugin_repo" init -q
git -C "$mock_plugin_repo" config user.email "test@example.com"
git -C "$mock_plugin_repo" config user.name "Test User"
cat >"$mock_plugin_repo/plugins/demo/main.sh" <<'EOF'
#!/usr/bin/env bash
export LCT_PLUGIN_TEST_VERSION="v1.0.0"
EOF
cat >"$mock_plugin_repo/plugins/demo/config.yaml" <<'EOF'
configs: []
dotfiles: []
other: []
EOF
git -C "$mock_plugin_repo" add plugins/demo/main.sh plugins/demo/config.yaml
git -C "$mock_plugin_repo" commit -q -m "initial plugin"
git -C "$mock_plugin_repo" tag v1.0.0

cat >"$mock_plugin_repo/plugins/demo/main.sh" <<'EOF'
#!/usr/bin/env bash
export LCT_PLUGIN_TEST_VERSION="v1.1.0"
EOF
git -C "$mock_plugin_repo" add plugins/demo/main.sh
git -C "$mock_plugin_repo" commit -q -m "plugin update"
git -C "$mock_plugin_repo" tag v1.1.0

it "installs the latest plugin version and shows it in plugin list"
approve "${cli} plugin install example/lct-plugins.demo" "plugin_install_latest"
approve "${cli} plugin list" "plugin_list_latest"

it "pins a plugin to a specific version and preserves that pin"
approve "${cli} plugin remove example/lct-plugins.demo" "plugin_remove"
approve "${cli} plugin install example/lct-plugins.demo@v1.0.0" "plugin_install_pinned"
approve "${cli} plugin list" "plugin_list_pinned"
approve "cat $tmpdir/.config/lct/config.yaml" "plugin_config_pinned"
approve "${cli} plugin install example/lct-plugins.demo" "plugin_install_respects_pin"

it "migrates a legacy install without reinstalling the plugin payload"
rm -rf "$tmpdir/.local/share/lct/plugins/example-lct-plugins-demo" "$tmpdir/.cache/lct/plugins/example/lct-plugins"
mkdir -p "$tmpdir/.cache/lct/plugins/example"
git clone -q "file://${tmpdir}/mock-github/example/lct-plugins" "$tmpdir/.cache/lct/plugins/example/lct-plugins"
mkdir -p "$tmpdir/.local/share/lct/plugins/example-lct-plugins-demo"
cp -R "$tmpdir/.cache/lct/plugins/example/lct-plugins/plugins/demo"/. "$tmpdir/.local/share/lct/plugins/example-lct-plugins-demo"/
legacy_commit="$(git -C "$tmpdir/.cache/lct/plugins/example/lct-plugins" rev-parse HEAD)"
cat >"$tmpdir/.cache/lct/plugins/example/lct-plugins/.lct-cache" <<EOF
repo_url=file://${tmpdir}/mock-github/example/lct-plugins
cached_commit=${legacy_commit}
installed_commit=${legacy_commit}
subpath=plugins/demo
updated_at=2026-07-03T00:00:00Z
EOF
yq -i '.plugins = ["example/lct-plugins.demo"]' "$tmpdir/.config/lct/config.yaml"
approve "${cli} plugin install example/lct-plugins.demo" "plugin_install_migrates_legacy"
approve "${cli} plugin list" "plugin_list_migrated"

it "validates an idempotent local plugin"
approve "${cli} plugin validate fixtures/plugins/idempotent" "plugin_validate_idempotent"
approve "if [[ ! -e fixtures/plugins/idempotent/.validation-state ]]; then echo 'plugin source unchanged'; else echo 'plugin source modified'; fi" "plugin_validate_source_unchanged"

it "identifies the failing command in a non-idempotent local plugin"
approve "${cli} plugin validate fixtures/plugins/non-idempotent 2>&1 | sed -E -e \"s#mkdir: cannot create directory '(.*)':#mkdir: \\1:#\" -e 's#mkdir: .*/home/#mkdir: <VALIDATION_HOME>/#'" "plugin_validate_non_idempotent"
expect_exit_code 1
