#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(<"$PROJECT_ROOT/VERSION")
PKGBUILD="$PROJECT_ROOT/packaging/arch/PKGBUILD"
SPECFILE="$PROJECT_ROOT/packaging/fedora/restart-to-macos.spec"

sed -i "s/^pkgver=.*/pkgver=$VERSION/" "$PKGBUILD"
sed -i "s/^Version:[[:space:]]*.*/Version:        $VERSION/" "$SPECFILE"
sed -i "s/^\* .* - [0-9][0-9.]*-1$/* $(LC_ALL=C date '+%a %b %d %Y') Jordan Brough <jtbrough@users.noreply.github.com> - $VERSION-1/" "$SPECFILE"

printf 'Synced package metadata to VERSION=%s\n' "$VERSION"
