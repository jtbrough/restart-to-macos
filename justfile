set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  @just --list

lint:
  shellcheck install.sh bin/restart-to-macos bin/restart-to-macos-uninstall libexec/restart-to-macos-helper tests/*.sh scripts/*.sh
  actionlint .github/workflows/ci.yml

validate-desktop:
  tmpdir="$(mktemp -d)"; trap 'rm -rf -- "$tmpdir"' EXIT; ./install.sh --destdir "$tmpdir" --prefix /usr --package-build; desktop-file-validate "$tmpdir/usr/share/applications/restart-to-macos.desktop"

validate-policy:
  xmllint --noout share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy.in

validate:
  just validate-desktop
  just validate-policy

test:
  tests/test.sh

build-arch:
  tests/build-arch-package.sh

build-fedora:
  tests/build-fedora-package.sh

prepare-release:
  scripts/prepare-release.sh

ci:
  just lint
  just validate
  just test
