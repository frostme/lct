#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p "$HOME/.example-plugin"
mkdir -p "$PWD/.validation-state"
printf '%s\n' "configured" >"$HOME/.example-plugin/config"
