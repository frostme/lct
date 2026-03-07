#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "self-update command"

it "updates when a newer release is available"
approve "${cli} self-update | sed -E 's/${LCT_VERSION}/CURRENT_VERSION/g' | sed -E 's/${UPDATE_VERSION}/UPDATE_VERSION/g'" "self_update"

it "does nothing when already up to date"
approve "MOCK_LCT_LATEST_TAG=v${LCT_VERSION} ${cli} self-update | sed -E 's/${LCT_VERSION}/CURRENT_VERSION/g'" "self_update_already_latest"

it "shows an error when latest version lookup fails"
approve "FAIL_CURL=1 ${cli} self-update" "self_update_lookup_error"
