send_plugin_setups() {
  command -v installed_plugins >/dev/null 2>&1 || return 0
  [ -n "${LCT_PLUGINS_DIR:-}" ] || return 0

  while IFS= read -r plugin; do
    setup_file="$LCT_PLUGINS_DIR/$plugin/setup.sh"
    if [[ -r "$setup_file" ]]; then
      cat "$setup_file"
      printf '\n'
    fi
  done < <(installed_plugins)
}
