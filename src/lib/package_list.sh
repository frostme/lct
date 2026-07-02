_lct_validate_package_list_config() {
  local manager="$1"

  if ! yq -e '.packages | type == "!!map"' "$LCT_CONFIG_FILE" >/dev/null 2>&1; then
    echo "❌ Invalid packages config: expected 'packages' to be a map in $LCT_CONFIG_FILE" >&2
    return 1
  fi

  if ! MANAGER="$manager" yq -e '
    (.packages[strenv(MANAGER)] == null) or
    (
      (.packages[strenv(MANAGER)] | type == "!!seq") and
      (.packages[strenv(MANAGER)] | all_c(type == "!!str"))
    )
  ' "$LCT_CONFIG_FILE" >/dev/null 2>&1; then
    echo "❌ Invalid packages config: expected 'packages.${manager}' to be a list of package names in $LCT_CONFIG_FILE" >&2
    return 1
  fi
}

_lct_validate_package_manager_argument() {
  local manager="$1"

  if _lct_package_manager_known "$manager"; then
    return 0
  fi

  echo "❌ Unknown package manager: $manager" >&2
  echo "Known package managers:" >&2
  _lct_package_manager_names | sed 's/^/  - /' >&2
  return 1
}

_lct_package_is_tracked() {
  local manager="$1"
  local package="$2"

  MANAGER="$manager" PACKAGE="$package" yq -e '
    (.packages[strenv(MANAGER)] // []) |
    any_c(. == strenv(PACKAGE))
  ' "$LCT_CONFIG_FILE" >/dev/null 2>&1
}

_lct_list_tracked_packages() {
  local manager="$1"

  MANAGER="$manager" yq -r '
    (.packages[strenv(MANAGER)] // [])[]
  ' "$LCT_CONFIG_FILE"
}

_lct_add_tracked_package() {
  local manager="$1"
  local package="$2"

  MANAGER="$manager" PACKAGE="$package" yq -i '
    .packages[strenv(MANAGER)] = (((.packages[strenv(MANAGER)] // []) + [strenv(PACKAGE)]) | unique)
  ' "$LCT_CONFIG_FILE"
}

_lct_remove_tracked_package() {
  local manager="$1"
  local package="$2"

  MANAGER="$manager" PACKAGE="$package" yq -i '
    .packages[strenv(MANAGER)] |= map(select(. != strenv(PACKAGE)))
  ' "$LCT_CONFIG_FILE"
}
