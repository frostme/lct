send_module_bin_path() {
  [ -n "${LCT_MODULES_BIN_DIR:-}" ] || return 0

  cat <<EOF
# lct modules bin
case ":\$PATH:" in
  *:"$LCT_MODULES_BIN_DIR":*)
    ;;
  *)
    export PATH="$LCT_MODULES_BIN_DIR:\$PATH"
    ;;
esac
EOF
}
