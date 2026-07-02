manager=${args[manager]}

ensure_config_defaults
if ! _lct_validate_package_manager_argument "$manager"; then
  exit 1
fi
if ! _lct_validate_package_list_config "$manager"; then
  exit 1
fi

mapfile -t packages < <(_lct_list_tracked_packages "$manager")
if ((${#packages[@]} == 0)); then
  echo "No packages tracked for $manager."
  exit 0
fi

printf '%s\n' "${packages[@]}"
