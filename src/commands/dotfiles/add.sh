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

dotfile_path="$HOME/$dotfile_input"
if [[ ! -e "$dotfile_path" ]]; then
  echo "❌ ERROR: dotfile not found at ${dotfile_path}" >&2
  exit 1
fi

append_unique "dotfiles" "$dotfile_input"
echo "Added dotfile ${dotfile_input}"
