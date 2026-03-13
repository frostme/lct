mapfile -t aliases < <(get_aliases 2>/dev/null || true)

if [[ ${#aliases[@]} -eq 0 ]]; then
  if [[ ${LCT_COMPLETIONS:-0} == 1 ]]; then
    exit 0
  fi

  echo "No aliases configured."
  exit 0
fi

printf '%s\n' "${aliases[@]}"
