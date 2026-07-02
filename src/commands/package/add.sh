manager=${args[manager]}
package=${args[package]}

ensure_config_defaults
if ! _lct_validate_package_manager_argument "$manager"; then
  exit 1
fi
if ! _lct_validate_package_list_config "$manager"; then
  exit 1
fi

if _lct_package_is_tracked "$manager" "$package"; then
  echo "Package '$package' is already tracked for $manager."
  exit 0
fi

_lct_add_tracked_package "$manager" "$package"
echo "Added package '$package' to $manager."
