lib_type=${args[--type]:-"all"}

_hr() { printf '%*s\n' "70" '' | tr ' ' '─'; }
_h2() {
  printf '\n%s\n' "$1"
  _hr
}
_indent() { sed 's/^/  - /'; }
_cols() {
  if command -v column >/dev/null 2>&1; then
    sed 's/^  - /  /' | column -t | sed 's/^/  - /'
  else
    cat
  fi
}

# Define the ordered types + titles once
declare -a TYPES TITLES
case "$lib_type" in
all)
  TYPES=(tap formula cask mas whalebrew vscode)
  TITLES=("Taps" "Formulae" "Casks" "Mac App Store (mas)" "Whalebrew" "VS Code Extensions")
  ;;
formula)
  TYPES=(formula)
  TITLES=("Formulae")
  ;;
cask)
  TYPES=(cask)
  TITLES=("Casks")
  ;;
tap)
  TYPES=(tap)
  TITLES=("Taps")
  ;;
mas)
  TYPES=(mas)
  TITLES=("Mac App Store (mas)")
  ;;
whalebrew)
  TYPES=(whalebrew)
  TITLES=("Whalebrew")
  ;;
vscode)
  TYPES=(vscode)
  TITLES=("VS Code Extensions")
  ;;
*)
  printf "Unknown type: %s\nAllowed: all, formula, cask, tap, mas, whalebrew, vscode\n" "$lib_type" >&2
  return 2
  ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' RETURN

# Kick off all list calls in parallel, each writing to its own file
for i in "${!TYPES[@]}"; do
  type="${TYPES[$i]}"
  (
    (brew bundle list --file="$LCT_BREW_FILE" --"$type" 2>/dev/null || true) |
      sed '/^[[:space:]]*$/d' |
      LC_ALL=C sort -f
  ) >"$tmpdir/$type.txt" &
done

# Wait for all background jobs
wait

for i in "${!TYPES[@]}"; do
  type="${TYPES[$i]}"
  if [[ -s "$tmpdir/$type.txt" ]]; then
    _h2 "${TITLES[$i]}"
    cat "$tmpdir/$type.txt" | _indent | _cols
  fi
done
