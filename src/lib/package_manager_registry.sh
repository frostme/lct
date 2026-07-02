# Package manager registry fields:
# name|category|dependencies|detect_commands|install_handler|remove_handler|export_handler|restore_handler|bundle_filename
#
# Dependencies use typed identifiers (`manager:<name>` or `runtime:<name>`).
# Operation handlers are identifiers dispatched by package_manager.sh; they are
# never evaluated as shell input. `unsupported` records an intentional gap.
_lct_package_manager_registry() {
  cat <<'EOF'
brew|system|none|brew|brew|brew|brew|brew|Brewfile
pip|language|runtime:python|python,pip|pip|pip|pip|pip|requirements.txt
apt|system|none|apt-get,dpkg-query|apt|apt|apt|apt|apt-packages.txt
dnf|system|none|dnf|dnf|dnf|dnf|dnf|dnf-packages.txt
yum|system|none|yum|yum|yum|yum|yum|yum-packages.txt
zypper|system|none|zypper|zypper|zypper|zypper|zypper|zypper-packages.txt
pacman|system|none|pacman|pacman|pacman|pacman|pacman|pacman-packages.txt
aur|system|manager:pacman|paru,yay|aur|aur|aur|aur|aur-packages.txt
pkg|system|none|pkg|pkg|pkg|pkg|pkg|pkg-packages.txt
winget|system|none|winget|winget|winget|winget|winget|winget-packages.json
mise|runtime|none|mise|mise|mise|mise|mise|mise-packages.txt
nix|system|none|nix-env|nix|nix|nix|nix|nix-packages.txt
asdf|runtime|none|asdf|asdf|asdf|unsupported|unsupported|unsupported
flox|runtime|none|flox|flox|flox|unsupported|unsupported|unsupported
npm|language|runtime:node|npm|npm|npm|unsupported|unsupported|unsupported
pnpm|language|runtime:node|pnpm|pnpm|pnpm|unsupported|unsupported|unsupported
yarn|language|runtime:node|yarn|yarn|yarn|unsupported|unsupported|unsupported
bun|language|none|bun|bun|bun|unsupported|unsupported|unsupported
cargo|language|runtime:rust|cargo|cargo|cargo|unsupported|unsupported|unsupported
cargo-binstall|language|manager:cargo|cargo-binstall|cargo-binstall|cargo-binstall|unsupported|unsupported|unsupported
uv|language|none|uv|uv|uv|unsupported|unsupported|unsupported
gem|language|runtime:ruby|gem|gem|gem|unsupported|unsupported|unsupported
go|language|runtime:go|go|go|go|unsupported|unsupported|unsupported
composer|language|runtime:php|composer|composer|composer|unsupported|unsupported|unsupported
scoop|system|none|scoop|scoop|scoop|unsupported|unsupported|unsupported
EOF
}

_lct_package_manager_get() {
  local requested_manager="$1"
  local requested_field="$2"
  local name category dependencies detect_commands install_handler remove_handler
  local export_handler restore_handler bundle_filename

  case "$requested_field" in
  name | category | dependencies | detect_commands | install_handler | remove_handler | export_handler | restore_handler | bundle_filename) ;;
  *) return 1 ;;
  esac

  while IFS='|' read -r name category dependencies detect_commands install_handler remove_handler export_handler restore_handler bundle_filename; do
    [[ "$name" == "$requested_manager" ]] || continue
    case "$requested_field" in
    name) printf '%s\n' "$name" ;;
    category) printf '%s\n' "$category" ;;
    dependencies) printf '%s\n' "$dependencies" ;;
    detect_commands) printf '%s\n' "$detect_commands" ;;
    install_handler) printf '%s\n' "$install_handler" ;;
    remove_handler) printf '%s\n' "$remove_handler" ;;
    export_handler) printf '%s\n' "$export_handler" ;;
    restore_handler) printf '%s\n' "$restore_handler" ;;
    bundle_filename) printf '%s\n' "$bundle_filename" ;;
    esac
    return 0
  done < <(_lct_package_manager_registry)

  return 1
}

_lct_package_manager_known() {
  _lct_package_manager_get "$1" name >/dev/null 2>&1
}

_lct_package_manager_names() {
  local requested_category="${1:-}"
  local name category dependencies detect_commands install_handler remove_handler
  local export_handler restore_handler bundle_filename

  case "$requested_category" in
  "" | system | runtime | language) ;;
  *) return 1 ;;
  esac

  while IFS='|' read -r name category dependencies detect_commands install_handler remove_handler export_handler restore_handler bundle_filename; do
    [[ -z "$requested_category" || "$category" == "$requested_category" ]] || continue
    printf '%s\n' "$name"
  done < <(_lct_package_manager_registry)
}

_lct_package_manager_dependencies() {
  local dependencies dependency
  local -a dependency_items=()

  dependencies="$(_lct_package_manager_get "$1" dependencies)" || return 1
  [[ "$dependencies" != "none" ]] || return 0

  IFS=',' read -r -a dependency_items <<<"$dependencies"
  for dependency in "${dependency_items[@]}"; do
    printf '%s\n' "$dependency"
  done
}

_lct_validate_package_manager_registry() {
  local name category dependencies detect_commands install_handler remove_handler
  local export_handler restore_handler bundle_filename existing dependency dependency_type dependency_name
  local -a names=() dependency_items=()

  while IFS='|' read -r name category dependencies detect_commands install_handler remove_handler export_handler restore_handler bundle_filename; do
    [[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || return 1
    case "$category" in
    system | runtime | language) ;;
    *) return 1 ;;
    esac
    [[ "$detect_commands" =~ ^[a-z0-9][a-z0-9,-]*$ ]] || return 1

    case "$install_handler" in
    brew|apt|dnf|yum|zypper|pacman|aur|nix|asdf|flox|npm|pnpm|yarn|bun|cargo|cargo-binstall|pip|uv|gem|go|composer|winget|scoop|pkg|mise) ;;
    *) return 1 ;;
    esac

    case "$remove_handler" in
    brew|apt|dnf|yum|zypper|pacman|aur|nix|asdf|flox|npm|pnpm|yarn|bun|cargo|cargo-binstall|pip|uv|gem|go|composer|winget|scoop|pkg|mise) ;;
    *) return 1 ;;
    esac

    case "$export_handler" in
    unsupported|brew|pip|apt|dnf|yum|zypper|pacman|aur|nix|winget|pkg|mise) ;;
    *) return 1 ;;
    esac

    case "$restore_handler" in
    unsupported|brew|pip|apt|dnf|yum|zypper|pacman|aur|nix|winget|pkg|mise) ;;
    *) return 1 ;;
    esac

    if [[ "$export_handler" == "unsupported" || "$restore_handler" == "unsupported" ]]; then
      [[ "$export_handler" == "unsupported" && "$restore_handler" == "unsupported" ]] || return 1
      [[ "$bundle_filename" == "unsupported" ]] || return 1
    else
      [[ "$bundle_filename" != "unsupported" && -n "$bundle_filename" ]] || return 1
    fi

    for existing in "${names[@]}"; do
      [[ "$existing" != "$name" ]] || return 1
    done
    names+=("$name")
  done < <(_lct_package_manager_registry)

  ((${#names[@]} > 0)) || return 1

  while IFS='|' read -r name category dependencies detect_commands install_handler remove_handler export_handler restore_handler bundle_filename; do
    [[ "$dependencies" != "none" ]] || continue
    IFS=',' read -r -a dependency_items <<<"$dependencies"
    for dependency in "${dependency_items[@]}"; do
      dependency_type="${dependency%%:*}"
      dependency_name="${dependency#*:}"
      [[ -n "$dependency_name" && "$dependency_name" != "$dependency" ]] || return 1
      case "$dependency_type" in
      runtime)
        [[ "$dependency_name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || return 1
        ;;
      manager)
        _lct_package_manager_known "$dependency_name" || return 1
        ;;
      *) return 1 ;;
      esac
    done
  done < <(_lct_package_manager_registry)
}
