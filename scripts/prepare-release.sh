#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(<"$PROJECT_ROOT/VERSION")
PKGBUILD="$PROJECT_ROOT/packaging/arch/PKGBUILD"
REPO_URL="https://github.com/jtbrough/restart-to-macos"
TARBALL_URL="$REPO_URL/archive/refs/tags/v$VERSION.tar.gz"

TMP_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TMP_ROOT"' EXIT

usage() {
  cat <<EOF
Usage: scripts/prepare-release.sh [--tarball-url URL]

Downloads the release tarball for the current VERSION, computes its SHA256,
and updates packaging/arch/PKGBUILD in place.
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --tarball-url)
        [[ $# -ge 2 ]] || fail "--tarball-url requires a value"
        TARBALL_URL=$2
        shift 2
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

require_tools() {
  command -v curl >/dev/null 2>&1 || fail "curl is required"
  command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
}

download_tarball() {
  local output=$1
  curl --fail --location --silent --show-error "$TARBALL_URL" --output "$output"
}

update_pkgbuild_checksum() {
  local checksum=$1
  sed -i "s|^sha256sums=.*|sha256sums=('$checksum')|" "$PKGBUILD"
}

main() {
  local tarball checksum

  parse_args "$@"
  require_tools

  tarball="$TMP_ROOT/restart-to-macos-$VERSION.tar.gz"
  download_tarball "$tarball"
  checksum=$(sha256sum "$tarball" | awk '{print $1}')
  update_pkgbuild_checksum "$checksum"

  printf 'Updated %s with sha256 %s\n' "$PKGBUILD" "$checksum"
  printf 'Tarball URL: %s\n' "$TARBALL_URL"
}

main "$@"
