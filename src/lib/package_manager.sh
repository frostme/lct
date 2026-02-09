_lct_default_package_manager() {
  if [[ -n "${LCT_DEFAULT_PACKAGE_MANAGER:-}" ]]; then
    printf '%s\n' "$LCT_DEFAULT_PACKAGE_MANAGER"
    return
  fi

  case "$(uname -s)" in
    Darwin) echo "brew" ;;
    *) echo "mise" ;;
  esac
}

_lct_package_manager_candidates() {
  local requested="$1"
  local configured="$2"
  local fallback="$3"
  local manager seen_manager
  local -a seen=()

  for manager in "$requested" "$configured" "$fallback"; do
    [[ -n "$manager" ]] || continue
    for seen_manager in "${seen[@]}"; do
      [[ "$seen_manager" == "$manager" ]] && continue 2
    done
    printf '%s\n' "$manager"
    seen+=("$manager")
  done
}

_lct_install_library() {
  local manager="$1"
  local package="$2"
  local target

  case "$manager" in
    brew)
      brew install "$package" &&
        brew bundle add "$package" --file="$LCT_BREW_FILE"
      ;;
    mise)
      target="$package"
      [[ "$target" == *@* ]] || target="${package}@latest"
      mise use --global "$target" &&
        mise install "$target"
      ;;
    *)
      printf "Unsupported package manager: %s\n" "$manager" >&2
      return 1
      ;;
  esac
}

_lct_remove_library() {
  local manager="$1"
  local package="$2"
  local target

  case "$manager" in
    brew)
      brew uninstall "$package" &&
        brew bundle remove "$package" --file="$LCT_BREW_FILE"
      ;;
    mise)
      target="$package"
      [[ "$target" == *@* ]] || target="${package}@latest"
      mise uninstall "$target" || mise uninstall "$package"
      ;;
    *)
      printf "Unsupported package manager: %s\n" "$manager" >&2
      return 1
      ;;
  esac
}
