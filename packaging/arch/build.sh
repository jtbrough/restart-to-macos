#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
VERSION=$(<"$PROJECT_ROOT/VERSION")
PARENT_TMPDIR=${TMPDIR:-/tmp}
TMP_ROOT=$(mktemp -d "$PARENT_TMPDIR/restart-to-macos-arch.XXXXXX")
trap 'rm -rf -- "$TMP_ROOT"' EXIT

PKGDIR="$TMP_ROOT/pkg"
SRCDEST="$TMP_ROOT/src"

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

mkdir -p "$PKGDIR" "$SRCDEST"
create_source_archive "$SRCDEST/restart-to-macos-$VERSION.tar.gz"

cp "$PROJECT_ROOT/packaging/arch/PKGBUILD" "$PKGDIR/PKGBUILD"
sed -i "s|^pkgver=.*|pkgver=$VERSION|" "$PKGDIR/PKGBUILD"
sed -i "s|^source=.*|source=('restart-to-macos-$VERSION.tar.gz')|" "$PKGDIR/PKGBUILD"
sed -i "s|^sha256sums=.*|sha256sums=('SKIP')|" "$PKGDIR/PKGBUILD"

if [[ $(id -u) -eq 0 ]]; then
  useradd -m -u 1000 builder >/dev/null 2>&1 || true
  chown -R builder:builder "$TMP_ROOT"
  su builder -c "cd '$PKGDIR' && SRCDEST='$SRCDEST' PKGDEST='$TMP_ROOT/out' makepkg --nodeps --force --cleanbuild"
else
  cd "$PKGDIR"
  SRCDEST="$SRCDEST" PKGDEST="$TMP_ROOT/out" makepkg --nodeps --force --cleanbuild
fi

find "$TMP_ROOT/out" -maxdepth 1 -type f -name '*.pkg.tar*' | grep -q .
printf 'Arch package build succeeded\n'
