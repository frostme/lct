gum_available() {
  command -v gum >/dev/null 2>&1
}

gum_title() {
  local text="$1"
  if gum_available; then
    gum style --border normal --border-foreground 212 --padding "0 1" --margin "0 0 1 0" "$text"
  else
    printf '%s\n' "$text"
  fi
}

gum_spinner() {
  local title="$1"
  shift
  if gum_available; then
    gum spin --spinner line --title "$title" -- "$@"
  else
    printf '%s\n' "$title"
    "$@"
  fi
}

gum_confirm_prompt() {
  local prompt="$1"
  if gum_available; then
    gum confirm "$prompt"
  else
    read -r -p "$prompt [y/N]: " reply
    [[ "$reply" =~ ^[Yy]$ ]]
  fi
}

gum_choose_multi() {
  if gum_available; then
    gum choose --no-limit "$@"
  else
    printf '%s\n' "$@"
  fi
}

gum_filter_multi() {
  if gum_available; then
    gum filter --no-limit "$@"
  else
    cat
  fi
}

gum_pick_file() {
  local dir="$1"
  shift
  if gum_available; then
    gum file --directory "$dir" "$@"
  else
    return 1
  fi
}

gum_pager_view() {
  if gum_available; then
    gum pager --soft-wrap
  else
    cat
  fi
}

gum_format_block() {
  local type="$1"
  if gum_available; then
    gum format --type "$type"
  else
    cat
  fi
}

gum_join_vertical() {
  if gum_available; then
    gum join --vertical "$@"
  else
    printf '%s\n' "$@"
  fi
}
