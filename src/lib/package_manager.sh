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
  local target bin_dir

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
  npm)
    npm install -g "$package"
    ;;
  pnpm)
    pnpm add -g "$package"
    ;;
  yarn)
    yarn global add "$package"
    ;;
  bun)
    bun add -g "$package"
    ;;
  cargo)
    cargo install "$package"
    ;;
  cargo-binstall)
    cargo binstall -y "$package"
    ;;
  pip)
    pip install "$package"
    ;;
  uv)
    uv tool install "$package"
    ;;
  gem)
    gem install "$package"
    ;;
  go)
    target="$package"
    [[ "$target" == *@* ]] || target="${package}@latest"
    go install "$target"
    ;;
  composer)
    composer global require "$package"
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
  npm)
    npm uninstall -g "$package"
    ;;
  pnpm)
    pnpm remove -g "$package"
    ;;
  yarn)
    yarn global remove "$package"
    ;;
  bun)
    bun remove -g "$package"
    ;;
  cargo | cargo-binstall)
    cargo uninstall "$package"
    ;;
  pip)
    pip uninstall -y "$package"
    ;;
  uv)
    uv tool uninstall "$package"
    ;;
  gem)
    gem uninstall -x "$package"
    ;;
  go)
    if command -v go >/dev/null 2>&1; then
      bin_dir="${GOBIN:-$(go env GOPATH 2>/dev/null)/bin}"
      rm -f "${bin_dir%/}/$(basename "$package")"
    fi
    ;;
  composer)
    composer global remove "$package"
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

_lct_package_bundle_filename() {
  local manager="$1"
  case "$manager" in
  brew) echo "Brewfile" ;;
  pip) echo "requirements.txt" ;;
  winget) echo "winget-packages.json" ;;
  mise) echo "mise-packages.txt" ;;
  nix) echo "nix-packages.txt" ;;
  apt | dnf | yum | zypper | pacman | aur | pkg) echo "packages.txt" ;;
  *) echo "${manager}.packages" ;;
  esac
}

_lct_package_bundle_known_files() {
  cat <<'EOF'
Brewfile
requirements.txt
packages.txt
winget-packages.json
mise-packages.txt
nix-packages.txt
EOF
}

_lct_can_dump_package_bundle() {
  local manager="$1"
  case "$manager" in
  brew) command -v brew >/dev/null 2>&1 ;;
  pip) command -v python >/dev/null 2>&1 || command -v pip >/dev/null 2>&1 ;;
  apt) command -v dpkg >/dev/null 2>&1 ;;
  dnf) command -v dnf >/dev/null 2>&1 ;;
  yum) command -v yum >/dev/null 2>&1 ;;
  zypper) command -v zypper >/dev/null 2>&1 ;;
  pacman) command -v pacman >/dev/null 2>&1 ;;
  aur) command -v paru >/dev/null 2>&1 || command -v yay >/dev/null 2>&1 ;;
  nix) command -v nix-env >/dev/null 2>&1 ;;
  winget) command -v winget >/dev/null 2>&1 ;;
  pkg) command -v pkg >/dev/null 2>&1 ;;
  mise) command -v mise >/dev/null 2>&1 ;;
  *) return 1 ;;
  esac
}

_lct_dump_package_bundle() {
  local manager="$1"
  local output_file="$2"

  case "$manager" in
  brew)
    brew bundle dump --describe --force --file="$output_file" >/dev/null
    ;;
  pip)
    if command -v python >/dev/null 2>&1; then
      python -m pip freeze >"$output_file"
    else
      pip freeze >"$output_file"
    fi
    ;;
  apt)
    dpkg --get-selections >"$output_file"
    ;;
  dnf)
    dnf list installed >"$output_file"
    ;;
  yum)
    yum list installed >"$output_file"
    ;;
  zypper)
    zypper search --installed-only >"$output_file"
    ;;
  pacman)
    pacman -Q >"$output_file"
    ;;
  aur)
    if command -v paru >/dev/null 2>&1; then
      paru -Q >"$output_file"
    else
      yay -Q >"$output_file"
    fi
    ;;
  nix)
    nix-env -q >"$output_file"
    ;;
  winget)
    winget export --output "$output_file" --accept-source-agreements
    ;;
  pkg)
    pkg info >"$output_file"
    ;;
  mise)
    mise ls --installed >"$output_file"
    ;;
  *)
    printf "Unsupported package manager for gather bundle export: %s\n" "$manager" >&2
    return 1
    ;;
  esac
}

_lct_gather_package_bundle() {
  local output_dir="$1"
  local default_manager manager bundle_name bundle_path
  local -a managers=()
  default_manager="$(_lct_default_package_manager)"

  mapfile -t managers < <(_lct_package_manager_candidates "" "${LCT_PACKAGE_MANAGER:-}" "$default_manager")
  for manager in "${managers[@]}"; do
    if ! _lct_can_dump_package_bundle "$manager"; then
      continue
    fi

    bundle_name="$(_lct_package_bundle_filename "$manager")"
    bundle_path="${output_dir%/}/$bundle_name"

    if _lct_dump_package_bundle "$manager" "$bundle_path"; then
      echo "Generated ${bundle_name} from ${manager} package manager"
      return 0
    fi

    echo "⚠ Failed to generate package bundle for manager: $manager" >&2
  done

  echo "⚠ Skipping package bundle export: no supported package manager command found"
  return 0
}
