_lct_default_package_manager() {
  if [[ -n "${LCT_DEFAULT_PACKAGE_MANAGER:-}" ]]; then
    printf '%s\n' "$LCT_DEFAULT_PACKAGE_MANAGER"
    return
  fi

  case "$(uname -s)" in
  Darwin) echo "brew" ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case "${ID:-}" in
      ubuntu | debian) echo "apt" ;;
      fedora) echo "dnf" ;;
      rhel | centos | rocky | almalinux | amazon) echo "yum" ;;
      arch | manjaro) echo "pacman" ;;
      opensuse* | suse) echo "zypper" ;;
      nixos) echo "nix" ;;
      *)
        if [[ -n "${ID_LIKE:-}" ]]; then
          case "$ID_LIKE" in
          *debian*) echo "apt" ;;
          *rhel* | *fedora*) echo "dnf" ;;
          *suse*) echo "zypper" ;;
          *) echo "mise" ;;
          esac
        else
          echo "mise"
        fi
        ;;
      esac
    else
      echo "mise"
    fi
    ;;
  FreeBSD) echo "pkg" ;;
  MINGW* | MSYS* | CYGWIN*) echo "winget" ;;
  *) echo "mise" ;;
  esac
}

_lct_package_manager_candidates() {
  local requested="$1"
  local configured="$2"
  local fallback="$3"
  local manager seen_manager
  local -a seen=()

  for manager in "$requested" "$configured" "$fallback"; do
    [[ -n "$manager" ]] || continue
    for seen_manager in "${seen[@]}"; do
      [[ "$seen_manager" == "$manager" ]] && continue 2
    done
    printf '%s\n' "$manager"
    seen+=("$manager")
  done
}

_lct_package_manager_file() {
  local manager="$1"
  case "$manager" in
  brew) echo "$LCT_BREW_FILE" ;;
  *) echo "$LCT_SHARE_DIR/${manager}.list" ;;
  esac
}

_lct_record_package() {
  local manager="$1"
  local package="$2"
  local action="$3" # add|remove
  local file="$(_lct_package_manager_file "$manager")"

  [[ -n "$file" ]] || return 0
  [[ -f "$file" ]] || touch "$file"

  case "$action" in
  add)
    if ! grep -Fxq "\"$package\"" "$file"; then
      printf '%s\n' "$package" >>"$file"
    fi
    ;;
  remove)
    if grep -Fxq "\"$package\"" "$file"; then
      grep -Fxv "\"$package\"" "$file" >"$file.tmp" && mv "$file.tmp" "$file"
    fi
    ;;
  esac
}

_lct_install_library() {
  local manager="$1"
  local package="$2"
  local target

  case "$manager" in
  brew)
    brew install "$package" &&
      brew bundle add "$package" --file="$LCT_BREW_FILE"
    ;;
  apt)
    apt-get install -y "$package"
    ;;
  dnf)
    dnf install -y "$package"
    ;;
  yum)
    yum install -y "$package"
    ;;
  zypper)
    zypper --non-interactive install -y "$package"
    ;;
  pacman)
    pacman -S --noconfirm "$package"
    ;;
  aur)
    if command -v paru >/dev/null 2>&1; then
      paru -S --noconfirm "$package"
    else
      yay -S --noconfirm "$package"
    fi
    ;;
  nix)
    nix-env -iA "nixpkgs.${package}"
    ;;
  asdf)
    asdf plugin-add "$package" >/dev/null 2>&1 || true
    asdf install "$package" latest
    asdf global "$package" latest
    ;;
  flox)
    flox install "$package"
    ;;
  winget)
    winget install --accept-source-agreements --accept-package-agreements "$package"
    ;;
  scoop)
    scoop install "$package"
    ;;
  pkg)
    pkg install -y "$package"
    ;;
  mise)
    target="$package"
    [[ "$target" == *@* ]] || target="${package}@latest"
    mise use --global "$target" &&
      mise install "$target"
    ;;
  *)
    printf "Unsupported package manager: %s\n" "$manager" >&2
    return 1
    ;;
  esac

  _lct_record_package "$manager" "$package" add
}

_lct_remove_library() {
  local manager="$1"
  local package="$2"
  local target

  case "$manager" in
  brew)
    brew uninstall "$package" &&
      brew bundle remove "$package" --file="$LCT_BREW_FILE"
    ;;
  apt)
    apt-get remove -y "$package"
    ;;
  dnf)
    dnf remove -y "$package"
    ;;
  yum)
    yum remove -y "$package"
    ;;
  zypper)
    zypper --non-interactive remove -y "$package"
    ;;
  pacman)
    pacman -Rns --noconfirm "$package"
    ;;
  aur)
    if command -v paru >/dev/null 2>&1; then
      paru -Rns --noconfirm "$package"
    else
      yay -Rns --noconfirm "$package"
    fi
    ;;
  nix)
    nix-env -e "$package"
    ;;
  asdf)
    asdf global "$package" system >/dev/null 2>&1 || true
    asdf uninstall "$package" latest
    ;;
  flox)
    flox uninstall "$package"
    ;;
  winget)
    winget uninstall --accept-source-agreements --accept-package-agreements "$package"
    ;;
  scoop)
    scoop uninstall "$package"
    ;;
  pkg)
    pkg delete -y "$package"
    ;;
  mise)
    target="$package"
    [[ "$target" == *@* ]] || target="${package}@latest"
    mise uninstall "$target" || mise uninstall "$package"
    ;;
  *)
    printf "Unsupported package manager: %s\n" "$manager" >&2
    return 1
    ;;
  esac

  _lct_record_package "$manager" "$package" remove
}
