set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  @just --list

lint:
  shellcheck install.sh src/bin/restart-to-macos src/bin/restart-to-macos-uninstall src/libexec/restart-to-macos-helper tests/*.sh tools/*.sh packaging/*/*.sh
  actionlint .github/workflows/ci.yml .github/workflows/release.yml

validate-desktop:
  tmpdir="$(mktemp -d)"; trap 'rm -rf -- "$tmpdir"' EXIT; ./install.sh --destdir "$tmpdir" --prefix /usr --package-build; desktop-file-validate "$tmpdir/usr/share/applications/restart-to-macos.desktop"

validate-policy:
  xmllint --noout src/share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy.in

validate:
  tools/check-version-sync.sh
  just validate-desktop
  just validate-policy

test:
  tests/test.sh

build-arch:
  packaging/arch/build.sh

build-fedora:
  packaging/fedora/build.sh

prepare-release:
  tools/prepare-release.sh

ci:
  just lint
  just validate
  just test
