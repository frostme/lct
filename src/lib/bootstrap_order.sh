LCT_DEFAULT_BOOTSTRAP_ORDER=(
  packages
  configs
  projects
  plugins
  modules
  secrets
)

join_bootstrap_phases() {
  local separator=""
  local joined=""
  local phase

  for phase in "$@"; do
    joined+="${separator}${phase}"
    separator=", "
  done

  printf '%s\n' "$joined"
}

resolve_bootstrap_order() {
  local config_file="$1"
  local order_type invalid_index phase seen_phase required_phase
  local found
  local -a seen_phases=()
  local -a missing_phases=()

  order_type="$(yq -r '.bootstrap_order | type' "$config_file" 2>/dev/null)" || {
    echo "❌ Invalid YAML in $config_file; unable to resolve bootstrap_order." >&2
    return 1
  }

  declare -ga BOOTSTRAP_ORDER
  BOOTSTRAP_ORDER=()

  case "$order_type" in
  '!!null')
    BOOTSTRAP_ORDER=("${LCT_DEFAULT_BOOTSTRAP_ORDER[@]}")
    return 0
    ;;
  '!!seq')
    ;;
  *)
    echo "❌ Invalid bootstrap_order in $config_file: expected a YAML list, got ${order_type#!!}." >&2
    return 1
    ;;
  esac

  invalid_index="$(yq -r '.bootstrap_order | to_entries[] | select(.value | type != "!!str") | .key' "$config_file" | head -n 1)"
  if [[ -n "$invalid_index" ]]; then
    echo "❌ Invalid bootstrap_order in $config_file: item $invalid_index must be a phase name." >&2
    return 1
  fi

  mapfile -t BOOTSTRAP_ORDER < <(yq -r '.bootstrap_order[]' "$config_file")

  for phase in "${BOOTSTRAP_ORDER[@]}"; do
    case "$phase" in
    packages | configs | projects | plugins | modules | secrets)
      ;;
    *)
      echo "❌ Invalid bootstrap_order in $config_file: unknown phase '$phase'." >&2
      echo "Supported phases: $(join_bootstrap_phases "${LCT_DEFAULT_BOOTSTRAP_ORDER[@]}")" >&2
      return 1
      ;;
    esac

    for seen_phase in "${seen_phases[@]}"; do
      if [[ "$phase" == "$seen_phase" ]]; then
        echo "❌ Invalid bootstrap_order in $config_file: duplicate phase '$phase'." >&2
        return 1
      fi
    done
    seen_phases+=("$phase")
  done

  for required_phase in "${LCT_DEFAULT_BOOTSTRAP_ORDER[@]}"; do
    found=0
    for phase in "${BOOTSTRAP_ORDER[@]}"; do
      if [[ "$phase" == "$required_phase" ]]; then
        found=1
        break
      fi
    done
    ((found)) || missing_phases+=("$required_phase")
  done

  if ((${#missing_phases[@]})); then
    echo "❌ Invalid bootstrap_order in $config_file: missing phase(s): $(join_bootstrap_phases "${missing_phases[@]}")." >&2
    return 1
  fi
}

print_bootstrap_order() {
  local separator=""
  local phase

  printf 'Bootstrap execution order: '
  for phase in "${BOOTSTRAP_ORDER[@]}"; do
    printf '%s%s' "$separator" "$phase"
    separator=" -> "
  done
  printf '\n'
}
