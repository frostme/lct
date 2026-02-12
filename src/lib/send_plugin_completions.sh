send_plugin_completions() {
  command -v installed_plugins >/dev/null 2>&1 || return 0
  [ -n "${LCT_PLUGINS_DIR:-}" ] || return 0

  while IFS= read -r plugin; do
    completion_file="$LCT_PLUGINS_DIR/$plugin/completions.sh"
    if [[ -r "$completion_file" ]]; then
      cat "$completion_file"
      printf '\n'
    fi
  done < <(installed_plugins)
}
