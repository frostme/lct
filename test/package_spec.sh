#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "package command"

it "lists an empty manager-specific package list"
approve "${cli} package list brew" "package_list_empty"

it "adds and lists packages for top-level and language managers"
approve "${cli} package add brew wget" "package_add_brew"
approve "${cli} package add pnpm '@dotenvx/dotenvx'" "package_add_pnpm"
approve "${cli} package list brew" "package_list_brew"
approve "${cli} package list pnpm" "package_list_pnpm"

it "treats duplicate additions as idempotent"
approve "${cli} package add brew wget" "package_add_duplicate"
approve "${cli} package list brew" "package_list_after_duplicate"

it "removes tracked packages"
approve "${cli} package remove brew wget" "package_remove_brew"
approve "${cli} package list brew" "package_list_after_remove"

it "handles an untracked package without changing the list"
approve "${cli} package remove brew missing" "package_remove_missing"
approve "${cli} package list brew" "package_list_after_missing_remove"

it "rejects a missing package name"
approve "${cli} package add brew" "package_add_missing_name"
expect_exit_code 1

it "rejects unknown package managers"
approve "${cli} package list unknown" "package_unknown_manager"
expect_exit_code 1
