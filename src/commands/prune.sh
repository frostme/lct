dry_run=${args[--dry]:-0}
prune_unused=${args[--unused]:-0}
prune_plugins=${args[--plugins]:-0}
prune_cache=${args[--cache]:-0}
directories_to_prune=()

# TODO: Implement prune unused logic
# if [[ $prune_unused -eq 1 ]]; then
# fi

# TODO  Implement prune unused plugins logic
if [[ $prune_plugins -eq 1 ]]; then
  mapfile -t cached < <(cached_plugins | sort -u)
  mapfile -t installed < <(installed_plugins | sort -u)
  mapfile -t desired_slugs < <(
    printf '%s\n' "${PLUGINS[@]}" |
      while IFS= read -r p; do plugin_key_slug "$p"; done |
      sort -u
  )

  mapfile -t current_entries < <(
    {
      cached_plugins
      installed_plugins
    } | sort -u
  )

  mapfile -t current_pairs < <(
    printf '%s\n' "${current_entries[@]}" |
      while IFS= read -r entry; do
        printf '%s\t%s\n' "$(plugin_key_slug "$entry")" "$entry"
      done |
      sort -u
  )

  mapfile -t current_slugs < <(
    printf '%s\n' "${current_pairs[@]}" | cut -f1 | sort -u
  )

  mapfile -t stale_slugs < <(
    comm -23 \
      <(printf '%s\n' "${current_slugs[@]}") \
      <(printf '%s\n' "${desired_slugs[@]}")
  )

  # ((${#stale_slugs[@]})) || return 0
  for slug in "${stale_slugs[@]}"; do
    while IFS=$'\t' read -r pair_slug entry; do
      [[ "$pair_slug" == "$slug" ]] || continue

      local cache_path inst_path
      cache_path="$(plugin_paths_for_entry "$LCT_PLUGINS_CACHE_DIR" "$entry")"
      inst_path="$(plugin_paths_for_entry "$LCT_PLUGINS_DIR" "$entry")"

      directories_to_prune+=("$cache_path" "$inst_path")
    done < <(printf '%s\n' "${current_pairs[@]}")
  done
fi

if [[ $prune_cache -eq 1 ]]; then
  # Gather plugins cache
  mapfile -t plugin_dirs < <(
    find "$LCT_PLUGINS_CACHE_DIR" \
      -type d \
      -name '.*' -prune -o \
      -type d \
      ! -path "$LCT_PLUGINS_CACHE_DIR" \
      -print
  )

  directories_to_prune+=("${plugin_dirs[@]}")
fi

if [[ dry_run -eq 1 ]]; then
  if [[ ${#directories_to_prune[@]} -eq 0 ]]; then
    echo "No directories to prune."
  else
    echo "Dry Run: The following directories would be pruned:"
    for dir in "${directories_to_prune[@]}"; do
      echo "- $dir"
    done
  fi
else
  if [[ ${#directories_to_prune[@]} -eq 0 ]]; then
    echo "No directories to prune."
  else
    printf '%s\n' "${directories_to_prune[@]}" |
      sort -r |
      while IFS= read -r dir; do
        rm -rf -- "$dir"
        printf '.\n'
      done |
      pv -l -s "${#directories_to_prune[@]}" >/dev/null
    echo "Pruning complete."
  fi
fi
