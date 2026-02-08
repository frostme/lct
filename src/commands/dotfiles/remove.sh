dotfile_input=${args[file]}

if [[ ! -f "$LCT_CONFIG_FILE" ]]; then
  echo "❌ ERROR: config.yaml file not found at ${LCT_CONFIG_FILE}" >&2
  exit 1
fi

if [[ -z "$dotfile_input" ]]; then
  echo "❌ ERROR: dotfile is required" >&2
  exit 1
fi

if [[ "$dotfile_input" == "$HOME/"* ]]; then
  dotfile_input="${dotfile_input#"$HOME/"}"
elif [[ "$dotfile_input" == /* ]]; then
  echo "❌ ERROR: dotfile must live under ${HOME}" >&2
  exit 1
fi

dotfile_input="${dotfile_input#./}"

if ! DOTFILE="$dotfile_input" yq -e '.dotfiles // [] | index(env.DOTFILE)' "$LCT_CONFIG_FILE" >/dev/null 2>&1; then
  echo "❌ ERROR: dotfile '${dotfile_input}' not found in config." >&2
  exit 1
fi

DOTFILE="$dotfile_input" yq -i '(.dotfiles // []) |= map(select(. != env.DOTFILE))' "$LCT_CONFIG_FILE"
echo "Removed dotfile ${dotfile_input}"
