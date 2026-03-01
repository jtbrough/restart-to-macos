#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME=restart-to-macos
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
VERSION=$(<"$SCRIPT_DIR/VERSION")

PREFIX=${PREFIX:-/usr/local}
DESTDIR=${DESTDIR:-}
INSTALL_POLKIT=1
DO_UNINSTALL=0
PACKAGE_BUILD=0

usage() {
  cat <<EOF
Usage: ./install.sh [options]

Options:
  --prefix PATH      Install prefix. Default: /usr/local
  --destdir PATH     Stage files under PATH before the prefix
  --no-polkit        Skip installing the polkit action
  --package-build    Omit self-managed uninstall metadata for native packages
  --uninstall        Remove files recorded by the last install
  -h, --help         Show this help
EOF
}

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

find_writable_probe() {
  local path=$1

  while [[ "$path" != "/" && ! -e "$path" ]]; do
    path=$(dirname -- "$path")
  done

  printf '%s\n' "$path"
}

require_root_if_needed() {
  local probe

  if [[ $(id -u) -eq 0 ]]; then
    return
  fi

  if [[ -n "$DESTDIR" ]]; then
    return
  fi

  probe=$(find_writable_probe "$INSTALL_ROOT")
  if [[ -w "$probe" ]]; then
    return
  fi

  exec sudo PREFIX="$PREFIX" DESTDIR="$DESTDIR" INSTALL_POLKIT="$INSTALL_POLKIT" \
    DO_UNINSTALL="$DO_UNINSTALL" PACKAGE_BUILD="$PACKAGE_BUILD" bash "$0" "$@"
}

render_template() {
  local input=$1
  local output=$2

  sed \
    -e "s|@BINDIR@|$RENDER_BINDIR|g" \
    -e "s|@LIBEXECDIR@|$RENDER_LIBEXECDIR|g" \
    "$input" >"$output"
}

desktop_link_target() {
  local target_user home_dir

  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    target_user=$SUDO_USER
    home_dir=$(getent passwd "$target_user" | cut -d: -f6)
  else
    home_dir=${HOME:-}
  fi

  [[ -n "$home_dir" ]] || return 1
  printf '%s\n' "$home_dir/.local/share/applications/$PROJECT_NAME.desktop"
}

write_manifest() {
  if [[ "$PACKAGE_BUILD" -eq 1 ]]; then
    return
  fi

  mkdir -p "$METADIR"
  printf '%s\n' "$VERSION" >"$VERSION_FILE"
  printf '%s\n' \
    "$BINDIR/restart-to-macos" \
    "$BINDIR/restart-to-macos-uninstall" \
    "$LIBEXECDIR/restart-to-macos-helper" \
    "$APPLICATIONS_DIR/restart-to-macos.desktop" \
    >"$MANIFEST_FILE"

  if [[ -n "${DESKTOP_LINK_PATH:-}" && -L "$DESKTOP_LINK_PATH" ]]; then
    printf '%s\n' "$DESKTOP_LINK_PATH" >>"$MANIFEST_FILE"
  fi

  if [[ "$INSTALL_POLKIT" -eq 1 ]]; then
    printf '%s\n' "$POLKIT_DIR/io.github.jtbrough.restart-to-macos.policy" >>"$MANIFEST_FILE"
  fi
}

install_file() {
  local mode=$1
  local src=$2
  local dest=$3

  mkdir -p "$(dirname -- "$dest")"
  install -m "$mode" "$src" "$dest"
}

refresh_desktop_db() {
  local target_dir=$1

  if [[ -n "$DESTDIR" ]]; then
    return
  fi

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$target_dir" >/dev/null 2>&1 || true
  fi
}

install_desktop_link() {
  local link_path link_dir

  if [[ -n "$DESTDIR" || "$PACKAGE_BUILD" -eq 1 ]]; then
    return
  fi

  link_path=$(desktop_link_target) || return
  link_dir=$(dirname -- "$link_path")
  mkdir -p "$link_dir"

  if [[ -e "$link_path" && ! -L "$link_path" ]]; then
    return
  fi

  ln -sfn "$APPLICATIONS_DIR/restart-to-macos.desktop" "$link_path"
  DESKTOP_LINK_PATH=$link_path
}

remove_manifest_files() {
  [[ -f "$MANIFEST_FILE" ]] || return 0

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    rm -f -- "$path"
  done <"$MANIFEST_FILE"
}

cleanup_metadata_dirs() {
  if [[ "$PACKAGE_BUILD" -eq 1 ]]; then
    return
  fi

  rm -f -- "$MANIFEST_FILE" "$VERSION_FILE"
  rmdir --ignore-fail-on-non-empty "$METADIR" 2>/dev/null || true
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --prefix)
        [[ $# -ge 2 ]] || fail "--prefix requires a value"
        PREFIX=$2
        shift 2
        ;;
      --destdir)
        [[ $# -ge 2 ]] || fail "--destdir requires a value"
        DESTDIR=$2
        shift 2
        ;;
      --no-polkit)
        INSTALL_POLKIT=0
        shift
        ;;
      --package-build)
        PACKAGE_BUILD=1
        shift
        ;;
      --uninstall)
        DO_UNINSTALL=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "unknown argument: $1"
        ;;
    esac
  done
}

setup_paths() {
  PREFIX=${PREFIX%/}
  DESTDIR=${DESTDIR%/}

  INSTALL_ROOT="${DESTDIR}${PREFIX}"
  RENDER_BINDIR="$PREFIX/bin"
  RENDER_LIBEXECDIR="$PREFIX/libexec"
  BINDIR="$INSTALL_ROOT/bin"
  LIBEXECDIR="$INSTALL_ROOT/libexec"
  DATADIR="$INSTALL_ROOT/share"
  APPLICATIONS_DIR="$DATADIR/applications"
  POLKIT_DIR="$DATADIR/polkit-1/actions"
  METADIR="$DATADIR/$PROJECT_NAME"
  MANIFEST_FILE="$METADIR/install-manifest.txt"
  VERSION_FILE="$METADIR/installed-version.txt"
}

report_mode() {
  local current_version=""

  if [[ "$PACKAGE_BUILD" -eq 0 && -f "$VERSION_FILE" ]]; then
    current_version=$(<"$VERSION_FILE")
  fi

  if [[ "$DO_UNINSTALL" -eq 1 ]]; then
    if [[ -n "$current_version" ]]; then
      log "Uninstalling $PROJECT_NAME $current_version from $INSTALL_ROOT"
    else
      log "Uninstalling $PROJECT_NAME from $INSTALL_ROOT"
    fi
    return
  fi

  if [[ -n "$current_version" ]]; then
    if [[ "$current_version" == "$VERSION" ]]; then
      log "Reinstalling $PROJECT_NAME $VERSION in $INSTALL_ROOT"
    else
      log "Updating $PROJECT_NAME from $current_version to $VERSION in $INSTALL_ROOT"
    fi
  else
    log "Installing $PROJECT_NAME $VERSION to $INSTALL_ROOT"
  fi
}

do_uninstall() {
  remove_manifest_files
  cleanup_metadata_dirs
  refresh_desktop_db "$APPLICATIONS_DIR"
}

do_install() {
  local tmpdir

  tmpdir=$(mktemp -d)
  trap 'rm -rf -- "'"$tmpdir"'"' EXIT

  remove_manifest_files

  install_file 0755 "$SCRIPT_DIR/bin/restart-to-macos" \
    "$BINDIR/restart-to-macos"
  if [[ "$PACKAGE_BUILD" -eq 0 ]]; then
    install_file 0755 "$SCRIPT_DIR/bin/restart-to-macos-uninstall" \
      "$BINDIR/restart-to-macos-uninstall"
  fi
  install_file 0755 "$SCRIPT_DIR/libexec/restart-to-macos-helper" \
    "$LIBEXECDIR/restart-to-macos-helper"

  render_template "$SCRIPT_DIR/share/applications/restart-to-macos.desktop.in" \
    "$tmpdir/restart-to-macos.desktop"
  install_file 0644 "$tmpdir/restart-to-macos.desktop" \
    "$APPLICATIONS_DIR/restart-to-macos.desktop"
  install_desktop_link

  if [[ "$INSTALL_POLKIT" -eq 1 ]]; then
    render_template "$SCRIPT_DIR/share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy.in" \
      "$tmpdir/io.github.jtbrough.restart-to-macos.policy"
    install_file 0644 "$tmpdir/io.github.jtbrough.restart-to-macos.policy" \
      "$POLKIT_DIR/io.github.jtbrough.restart-to-macos.policy"
  fi

  write_manifest
  refresh_desktop_db "$APPLICATIONS_DIR"
  trap - EXIT
  rm -rf -- "$tmpdir"
}

main() {
  parse_args "$@"
  setup_paths
  require_root_if_needed "$@"
  report_mode

  if [[ "$DO_UNINSTALL" -eq 1 ]]; then
    do_uninstall
  else
    do_install
  fi
}

main "$@"
