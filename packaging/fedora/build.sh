#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
VERSION=$(<"$PROJECT_ROOT/VERSION")

command -v rpmbuild >/dev/null 2>&1 || {
  printf 'rpmbuild is required\n' >&2
  exit 1
}

PARENT_TMPDIR=${TMPDIR:-/tmp}
TMP_ROOT=$(mktemp -d "$PARENT_TMPDIR/restart-to-macos-fedora.XXXXXX")
trap 'rm -rf -- "$TMP_ROOT"' EXIT

TOPDIR="$TMP_ROOT/rpmbuild"
TMPPATH="$TMP_ROOT/rpmtmp"
mkdir -p "$TOPDIR/SOURCES" "$TOPDIR/SPECS" "$TOPDIR/SRPMS" "$TOPDIR/RPMS" "$TOPDIR/BUILD" "$TOPDIR/BUILDROOT" "$TMPPATH"

create_source_archive() {
  local output=$1
  local stage

  if command -v git >/dev/null 2>&1 && git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$PROJECT_ROOT" archive \
      --format=tar.gz \
      --prefix="restart-to-macos-$VERSION/" \
      HEAD >"$output"
    return
  fi

  stage="$TMP_ROOT/restart-to-macos-$VERSION"
  mkdir -p "$stage"
  cp -a "$PROJECT_ROOT/." "$stage"
  rm -rf "$stage/.git" "$stage/.tmp" "$stage/dist" "$stage/pkg" "$stage/results"
  tar -C "$TMP_ROOT" -czf "$output" "restart-to-macos-$VERSION"
}

create_source_archive "$TOPDIR/SOURCES/restart-to-macos-$VERSION.tar.gz"
cp "$PROJECT_ROOT/packaging/fedora/restart-to-macos.spec" "$TOPDIR/SPECS/restart-to-macos.spec"
sed -i "s/^Version:[[:space:]]*.*/Version:        $VERSION/" "$TOPDIR/SPECS/restart-to-macos.spec"

rpmbuild -ba \
  --define "_topdir $TOPDIR" \
  --define "_sourcedir $TOPDIR/SOURCES" \
  --define "_tmppath $TMPPATH" \
  "$TOPDIR/SPECS/restart-to-macos.spec"

find "$TOPDIR/RPMS" -type f -name '*.rpm' | grep -q .
printf 'Fedora package build succeeded\n'
