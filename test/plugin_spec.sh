#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "plugin command"

it "validates an idempotent local plugin"
approve "${cli} plugin validate fixtures/plugins/idempotent" "plugin_validate_idempotent"
approve "if [[ ! -e fixtures/plugins/idempotent/.validation-state ]]; then echo 'plugin source unchanged'; else echo 'plugin source modified'; fi" "plugin_validate_source_unchanged"

it "identifies the failing command in a non-idempotent local plugin"
approve "${cli} plugin validate fixtures/plugins/non-idempotent 2>&1 | sed -E 's#mkdir: .*/home/.example-plugin#mkdir: <VALIDATION_HOME>/.example-plugin#'" "plugin_validate_non_idempotent"
expect_exit_code 1
