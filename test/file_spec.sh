#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/approvals.bash"

describe "file command"
work_dir="$tmpdir/work"
mkdir -p "$tmpdir/.config/alacritty/sub" "$work_dir"
touch "$tmpdir/.zshrc" "$tmpdir/.config/alacritty/sub/config.yml" "$work_dir/custom.conf"

it "adds and classifies files"
approve "${cli} file add \"$tmpdir/.zshrc\"" "file_add_dotfile"
approve "${cli} file add \"$tmpdir/.config/alacritty/sub/config.yml\"" "file_add_config"
approve "${cli} file add \"$work_dir/custom.conf\"" "file_add_other"
approve "${cli} file list" "file_list_after_add"

it "removes files by path"
approve "${cli} file remove \"$tmpdir/.zshrc\"" "file_remove_dotfile"
approve "${cli} file remove \"$tmpdir/.config/alacritty/sub/config.yml\"" "file_remove_config"
approve "${cli} file remove \"$work_dir/custom.conf\"" "file_remove"
approve "${cli} file list" "file_list_after_remove"

it "rejects absolute paths in file remove"
approve "${cli} file remove /etc/passwd" "file_remove_reject_absolute"

it "rejects .. segments in file remove"
approve "${cli} file remove \"work/../etc/passwd\"" "file_remove_reject_dotdot"
