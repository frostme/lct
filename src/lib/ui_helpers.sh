gum_available() {
  command -v gum >/dev/null 2>&1
}

lct_verbose_enabled() {
  [[ "${LCT_VERBOSE:-0}" == "1" ]]
}

lct_log_file_path() {
  printf '%s\n' "${LCT_DEBUG_LOG_FILE:-$HOME/.local/state/lct/debug.log}"
}

lct_init_logging() {
  local log_file
  log_file="$(lct_log_file_path)"
  mkdir -p "$(dirname "$log_file")"
  [[ -f "$log_file" ]] || : >"$log_file"
}

lct_log() {
  local level="$1"
  shift || true
  local message="$*"
  local log_file
  log_file="$(lct_log_file_path)"

  lct_init_logging || return 1

  if gum_available; then
    gum log -o "$log_file" --prefix "[lct]" -sl "$level" "$message" >/dev/null
    if lct_verbose_enabled; then
      gum log --prefix "[lct]" -sl "$level" "$message"
    fi
  else
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s [%s] %s\n' "$ts" "$level" "$message" >>"$log_file"
    if lct_verbose_enabled; then
      printf '%s [%s] %s\n' "$ts" "$level" "$message" >&2
    fi
  fi
}

lct_log_debug() {
  lct_log debug "$*"
}

lct_log_info() {
  lct_log info "$*"
}

lct_log_warn() {
  lct_log warn "$*"
}

lct_log_error() {
  lct_log error "$*"
}

lct_log_exception() {
  lct_log_error "$*"
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
