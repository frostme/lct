mapfile -t plugins < <(installed_plugins | LC_ALL=C sort -f)

if [[ ${#plugins[@]} -eq 0 ]]; then
  echo "No plugins installed."
  exit 0
fi

printf '%s\n' "${plugins[@]}"
