validate_local_plugin_idempotency() {
  local requested_path="$1"
  local plugin_dir entrypoint plugin_name bash_bin validation_root validation_home
  local validation_plugin_dir validation_entrypoint
  local runner log_file run_number status syntax_output

  if [[ ! -d "$requested_path" ]]; then
    echo "❌ ERROR: Plugin path is not a directory: $requested_path" >&2
    return 1
  fi

  plugin_dir="$(cd "$requested_path" && pwd -P)"
  entrypoint="$plugin_dir/main.sh"
  plugin_name="$(basename "$plugin_dir")"

  if [[ ! -f "$entrypoint" ]]; then
    echo "❌ ERROR: Plugin entrypoint not found: $requested_path/main.sh" >&2
    return 1
  fi

  bash_bin="$(command -v bash)"
  if ! syntax_output="$("$bash_bin" -n "$entrypoint" 2>&1)"; then
    echo "Validating plugin: $plugin_name"
    echo "Syntax check: failed"
    printf '%s\n' "$syntax_output" >&2
    echo "❌ Plugin validation failed: $plugin_name main.sh has invalid Bash syntax" >&2
    return 1
  fi

  if ! validation_root="$(mktemp -d "${TMPDIR:-/tmp}/lct-plugin-validate.XXXXXX")"; then
    echo "❌ ERROR: Unable to create a temporary plugin validation directory" >&2
    return 1
  fi
  validation_home="$validation_root/home"
  validation_plugin_dir="$validation_root/plugin"
  validation_entrypoint="$validation_plugin_dir/main.sh"
  runner="$validation_root/run-plugin.sh"
  if ! mkdir -p \
    "$validation_home/software" \
    "$validation_home/.config/lct" \
    "$validation_home/.local/share/lct" \
    "$validation_home/.local/state/lct" \
    "$validation_home/.cache/lct" \
    "$validation_home/code" \
    "$validation_root/tmp"; then
    echo "❌ ERROR: Unable to initialize temporary plugin validation directories" >&2
    rm -rf -- "$validation_root"
    return 1
  fi

  if ! cp -R "$plugin_dir" "$validation_plugin_dir"; then
    echo "❌ ERROR: Unable to copy the plugin into the temporary validation directory" >&2
    rm -rf -- "$validation_root"
    return 1
  fi

  if ! cat >"$runner" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

trap 'status=$?; failed_command=$BASH_COMMAND; trap - ERR; printf "Failed command: %s\n" "$failed_command" >&2; exit "$status"' ERR

cd "$LCT_PLUGIN_DIR"
# shellcheck disable=SC1090
source "$LCT_PLUGIN_ENTRYPOINT"
EOF
  then
    echo "❌ ERROR: Unable to create the temporary plugin validation runner" >&2
    rm -rf -- "$validation_root"
    return 1
  fi

  echo "Validating plugin: $plugin_name"
  echo "Syntax check: passed"

  for run_number in 1 2; do
    log_file="$validation_root/run-$run_number.log"
    if env -i \
      PATH="$PATH" \
      HOME="$validation_home" \
      TMPDIR="$validation_root/tmp" \
      LANG=C \
      LC_ALL=C \
      SOFTWARE_DIR="$validation_home/software" \
      CONFIG_DIR="$validation_home/.config" \
      SHARE_DIR="$validation_home/.local/share" \
      STATE_DIR="$validation_home/.local/state" \
      CACHE_DIR="$validation_home/.cache" \
      CODE_DIR="$validation_home/code" \
      LCT_SOFTWARE_DIR="$validation_home/software/lct" \
      LCT_CONFIG_DIR="$validation_home/.config/lct" \
      LCT_SHARE_DIR="$validation_home/.local/share/lct" \
      LCT_STATE_DIR="$validation_home/.local/state/lct" \
      LCT_CACHE_DIR="$validation_home/.cache/lct" \
      LCT_ENV_FILE="$validation_home/.local/share/lct/env.yaml" \
      LCT_CONFIG_FILE="$validation_home/.config/lct/config.yaml" \
      LCT_REMOTE_DIR="$validation_home/.local/share/lct/remote" \
      LCT_REMOTE_SECRETS_DIR="$validation_home/.local/share/lct/remote/secrets" \
      LCT_BREW_FILE="$validation_home/.local/share/lct/Brewfile" \
      LCT_ALIAS_FILE="$validation_home/.local/share/lct/alias.yaml" \
      LCT_INIT_FILE="$validation_home/.local/share/lct/.init_done" \
      LCT_PLUGINS_DIR="$validation_home/.local/share/lct/plugins" \
      LCT_PLUGINS_CACHE_DIR="$validation_home/.cache/lct/plugins" \
      LCT_MODULES_DIR="$validation_home/.local/share/lct/modules" \
      LCT_MODULES_CACHE_DIR="$validation_home/.cache/lct/modules" \
      LCT_MODULES_BIN_DIR="$validation_home/.local/share/lct/modules/bin" \
      LCT_DEBUG_LOG_FILE="$validation_home/.local/state/lct/debug.log" \
      LCT_PLUGIN_DIR="$validation_plugin_dir" \
      LCT_PLUGIN_ENTRYPOINT="$validation_entrypoint" \
      LCT_PLUGIN_VALIDATION=1 \
      LCT_PLUGIN_VALIDATION_RUN="$run_number" \
      "$bash_bin" --noprofile --norc "$runner" >"$log_file" 2>&1; then
      echo "Run $run_number/2: passed"
      continue
    else
      status=$?
    fi

    echo "Run $run_number/2: failed (exit $status)" >&2
    if [[ -s "$log_file" ]]; then
      echo "Plugin output:" >&2
      cat "$log_file" >&2
    fi
    echo "❌ Plugin validation failed: $plugin_name main.sh failed on run $run_number" >&2
    rm -rf -- "$validation_root"
    return 1
  done

  rm -rf -- "$validation_root"
  echo "✅ Plugin validation passed: $plugin_name main.sh completed twice"
}
