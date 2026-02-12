libname=${args[library]}
requested_manager=${args[--manager]:-}
default_manager=$(_lct_default_package_manager)

mapfile -t managers < <(_lct_package_manager_candidates "$requested_manager" "${LCT_PACKAGE_MANAGER:-}" "$default_manager")
if ((${#managers[@]} == 0)); then
  managers+=("$default_manager")
fi

declare -a errors=()

for manager in "${managers[@]}"; do
  if ! command -v "$manager" >/dev/null 2>&1; then
    printf "Package manager '%s' not available, trying next option.\n" "$manager" >&2
    errors+=("package manager '$manager' not found")
    continue
  fi

  printf "Using package manager: %s\n" "$manager"
  if _lct_remove_library "$manager" "$libname"; then
    exit 0
  fi

  printf "Removal via '%s' failed, trying next option.\n" "$manager" >&2
  errors+=("failed removing with '$manager'")
done

printf "Failed to remove %s.\n" "$libname" >&2
if ((${#errors[@]})); then
  printf "  - %s\n" "${errors[@]}" >&2
fi
exit 1
