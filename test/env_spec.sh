#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "env command"
it "sets and lists environment variables"
approve "${cli} env set SAMPLE_KEY sample-value" "env_set_sample"
approve "${cli} env list" "env_list"

it "sets an environment variable"
approve "${cli} env set API_KEY 123" "env_set_api_key"

it "unsets an environment variable"
approve "${cli} env unset API_KEY" "env_unset_api_key"
