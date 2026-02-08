#!/usr/bin/env bash
set -euo pipefail

REPO="frostme/lct"
INSTALL_DIR="${LCT_INSTALL_DIR:-/usr/local/bin}"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

log() {
  echo "[lct install] $*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

run_with_sudo() {
  if [[ -n "${SUDO_CMD:-}" ]]; then
    "${SUDO_CMD}" "$@"
  else
    "$@"
  fi
}

detect_platform() {
  local sys os_name arch_name gum_arch_name gum_os_name

  sys="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$sys" in
    linux) os_name="linux"; gum_os_name="Linux" ;;
    darwin) os_name="darwin"; gum_os_name="Darwin" ;;
    *)
      log "Unsupported OS: $sys"
      exit 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)
      arch_name="amd64"
      gum_arch_name="x86_64"
      ;;
    arm64|aarch64)
      arch_name="arm64"
      gum_arch_name="arm64"
      ;;
    *)
      log "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac

  OS="$os_name"
  ARCH="$arch_name"
  GUM_ARCH="$gum_arch_name"
  GUM_OS="$gum_os_name"
}

github_asset_url() {
  local repo="$1"
  local pattern="$2"
  local url

  url="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | \
    grep -Eo "\"browser_download_url\": *\"[^\"]*${pattern}[^\"]*\"" | \
    head -n 1 | cut -d'"' -f4)"

  if [[ -z "$url" ]]; then
    log "Could not find asset matching pattern '${pattern}' for ${repo}"
    exit 1
  fi

  echo "$url"
}

install_binary() {
  local src="$1"
  local dest="$2"

  if [[ ! -f "$src" ]]; then
    log "Binary not found at ${src}"
    exit 1
  fi

  run_with_sudo mkdir -p "$INSTALL_DIR"

  if command -v install >/dev/null 2>&1; then
    run_with_sudo install -m 0755 "$src" "$dest"
  else
    run_with_sudo cp "$src" "$dest"
    run_with_sudo chmod 0755 "$dest"
  fi
}

ensure_writable_install_dir() {
  if [[ ! -w "$INSTALL_DIR" ]]; then
    if command -v sudo >/dev/null 2>&1 && [[ "${SKIP_SUDO:-0}" != "1" ]]; then
      SUDO_CMD="sudo"
    elif [[ "$(id -u)" -ne 0 ]]; then
      log "Write access to ${INSTALL_DIR} is required. Re-run with sudo or set LCT_INSTALL_DIR."
      exit 1
    fi
  fi
}

install_lct() {
  log "Downloading latest lct release..."
  local asset_url tarball
  asset_url="$(github_asset_url "$REPO" "\\.tar\\.gz")"
  tarball="${TMP_ROOT}/lct.tar.gz"

  curl -fsSL "$asset_url" -o "$tarball"
  tar -xzf "$tarball" -C "$TMP_ROOT"

  local lct_binary="${TMP_ROOT}/lct"
  if [[ ! -f "$lct_binary" ]]; then
    lct_binary="$(find "$TMP_ROOT" -type f -name 'lct' | head -n 1)"
  fi

  if [[ -z "$lct_binary" ]]; then
    log "Downloaded archive did not contain the lct binary."
    exit 1
  fi

  install_binary "$lct_binary" "${INSTALL_DIR}/lct"
  log "Installed lct to ${INSTALL_DIR}/lct"
}

install_gum() {
  if command -v gum >/dev/null 2>&1; then
    log "gum already installed"
    return
  fi

  log "Installing gum dependency..."
  local pattern asset_url tarball gum_binary
  pattern="gum_.*_${GUM_OS}_${GUM_ARCH}\\.tar\\.gz"
  asset_url="$(github_asset_url "charmbracelet/gum" "$pattern")"
  tarball="${TMP_ROOT}/gum.tar.gz"

  curl -fsSL "$asset_url" -o "$tarball"
  tar -xzf "$tarball" -C "$TMP_ROOT"
  gum_binary="$(find "$TMP_ROOT" -type f -name 'gum' | head -n 1)"

  if [[ -z "$gum_binary" ]]; then
    log "Could not locate gum binary in downloaded archive."
    exit 1
  fi

  install_binary "$gum_binary" "${INSTALL_DIR}/gum"
  log "Installed gum to ${INSTALL_DIR}/gum"
}

install_yq() {
  if command -v yq >/dev/null 2>&1; then
    log "yq already installed"
    return
  fi

  log "Installing yq dependency..."
  local pattern asset_url yq_binary
  pattern="yq_${OS}_${ARCH}"
  asset_url="$(github_asset_url "mikefarah/yq" "$pattern")"
  yq_binary="${TMP_ROOT}/yq"

  curl -fsSL "$asset_url" -o "$yq_binary"
  install_binary "$yq_binary" "${INSTALL_DIR}/yq"
  log "Installed yq to ${INSTALL_DIR}/yq"
}

main() {
  require_cmd curl
  require_cmd tar
  require_cmd uname

  detect_platform
  ensure_writable_install_dir

  install_gum
  install_yq
  install_lct

  log "Done. Run 'lct --help' to get started."
}

main "$@"
