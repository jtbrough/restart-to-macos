# restart-to-macos

Cross-desktop launcher for Asahi Linux users who want a one-time restart into macOS.

The project installs:

- `restart-to-macos` in `bin/`
- `restart-to-macos-uninstall` in `bin/`
- `restart-to-macos-helper` in `libexec/`
- `restart-to-macos.desktop` in `share/applications/`
- an optional polkit action in `share/polkit-1/actions/`

The initial focus is a plain install script that:

- installs system-wide under a prefix such as `/usr/local`
- can be rerun safely
- replaces existing files in place when updating to a new release
- can uninstall what it installed

## Dependencies

Required:

- `asahi-bless`
- `polkit` providing `pkexec`
- `systemd` providing `systemctl`

Required for desktop launcher use:

- `zenity` or `kdialog`

Package guidance:

- Fedora Asahi: `sudo dnf install asahi-bless polkit systemd zenity`
- Arch/Asahi Arch: `sudo pacman -S asahi-bless polkit systemd zenity`

`kdialog` can replace `zenity` if you prefer KDE-native dialogs.

## Health Check

Use the built-in preflight check before installing or debugging:

```bash
restart-to-macos --check
```

The check verifies:

- the installed helper path
- `asahi-bless`
- `pkexec`
- `systemctl`
- a supported GUI confirmation backend

## Install

```bash
./install.sh
```

By default this installs under `/usr/local`.

Useful options:

```bash
./install.sh --prefix /usr/local
./install.sh --no-polkit
./install.sh --uninstall
```

For native package builds, the installer also supports:

```bash
./install.sh --destdir /path/to/stage --prefix /usr --package-build
```

`--package-build` skips the self-managed uninstall command and manifest files so
native package managers remain the sole source of truth for installed files.

## Uninstall

```bash
./install.sh --uninstall
```

Installed systems can also remove the project later with:

```bash
restart-to-macos-uninstall
```

## Packaging

Packaging metadata lives under `packaging/`:

- Arch: `packaging/arch/PKGBUILD`
- Fedora: `packaging/fedora/restart-to-macos.spec`
- Homebrew tap: `brew install jtbrough/tap/restart-to-macos`

Both package definitions reuse `install.sh --destdir` so the manual install path
and native package installs stay aligned.

Homebrew is a convenience install path, not the primary Linux packaging target.
It still depends on distro-provided host packages such as `asahi-bless`,
`polkit`, `systemd`, and `zenity` or `kdialog`.

Local package build helpers live under `tests/`:

- `tests/build-arch-package.sh`
- `tests/build-fedora-package.sh`

Release prep helper:

- `scripts/prepare-release.sh`

Before publishing a release tag, run:

```bash
scripts/prepare-release.sh
```

This downloads the GitHub tarball for `v$(cat VERSION)`, computes its SHA256,
and updates `packaging/arch/PKGBUILD` with the real checksum.

## Task Runner

`just` provides the main local entrypoints:

```bash
just lint
just validate
just test
just ci
just build-arch
just build-fedora
just prepare-release
```

The underlying shell scripts remain the source of truth for packaging and test
logic, and `just` only orchestrates them.

Task breakdown:

- `just lint`: `shellcheck` and `actionlint`
- `just validate`: rendered desktop entry validation and polkit XML validation
- `just test`: staged install and health-check tests
- `just ci`: local equivalent of the main CI lint/validate/test flow
- `just build-arch`: Arch package smoke build
- `just build-fedora`: Fedora RPM smoke build
- `just prepare-release`: update the Arch release checksum from the GitHub tag tarball

## Testing

Run the staged install test suite with:

```bash
just test
```

The test suite covers:

- manual install layout
- package-build layout
- `--no-polkit` install behavior
- update and uninstall behavior
- desktop and polkit template rendering
- runtime health checks for both passing and failing dependency states

## CI

GitHub Actions is configured in `.github/workflows/ci.yml` to run:

- `just ci`
- Arch package build smoke test
- Fedora RPM build smoke test
