#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(<"$PROJECT_ROOT/VERSION")

command -v rpmbuild >/dev/null 2>&1 || {
  printf 'rpmbuild is required\n' >&2
  exit 1
}

PARENT_TMPDIR=${TMPDIR:-/tmp}
TMP_ROOT=$(mktemp -d "$PARENT_TMPDIR/restart-to-macos-fedora.XXXXXX")
trap 'rm -rf -- "$TMP_ROOT"' EXIT

TOPDIR="$TMP_ROOT/rpmbuild"
mkdir -p "$TOPDIR/SOURCES" "$TOPDIR/SPECS" "$TOPDIR/SRPMS" "$TOPDIR/RPMS" "$TOPDIR/BUILD" "$TOPDIR/BUILDROOT"

STAGE="$TMP_ROOT/restart-to-macos-$VERSION"
cp -a "$PROJECT_ROOT/." "$STAGE"
rm -rf "$STAGE/.git"
tar -C "$TMP_ROOT" -czf "$TOPDIR/SOURCES/restart-to-macos-$VERSION.tar.gz" "restart-to-macos-$VERSION"
cp "$PROJECT_ROOT/packaging/fedora/restart-to-macos.spec" "$TOPDIR/SPECS/restart-to-macos.spec"

rpmbuild -ba \
  --define "_topdir $TOPDIR" \
  --define "_sourcedir $TOPDIR/SOURCES" \
  "$TOPDIR/SPECS/restart-to-macos.spec"

find "$TOPDIR/RPMS" -type f -name '*.rpm' | grep -q .
printf 'Fedora package build succeeded\n'
