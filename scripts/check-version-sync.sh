#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(<"$PROJECT_ROOT/VERSION")
PKGBUILD_VERSION=$(sed -n 's/^pkgver=//p' "$PROJECT_ROOT/packaging/arch/PKGBUILD")
SPEC_VERSION=$(sed -n 's/^Version:[[:space:]]*//p' "$PROJECT_ROOT/packaging/fedora/restart-to-macos.spec")

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

[[ "$PKGBUILD_VERSION" == "$VERSION" ]] || fail "PKGBUILD pkgver ($PKGBUILD_VERSION) does not match VERSION ($VERSION)"
[[ "$SPEC_VERSION" == "$VERSION" ]] || fail "RPM spec Version ($SPEC_VERSION) does not match VERSION ($VERSION)"

printf 'Version metadata is in sync at %s\n' "$VERSION"
