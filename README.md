# restart-to-macos

Cross-desktop launcher for Asahi Linux users who want a one-time restart into macOS.

## Install

Required host packages:

- `asahi-bless`
- `polkit` providing `pkexec`
- `systemd` providing `systemctl`

Required for interactive desktop use:

- `zenity` or `kdialog`

Typical dependency install:

- Fedora Asahi: `sudo dnf install asahi-bless polkit systemd zenity`
- Arch/Asahi Arch: `sudo pacman -S asahi-bless polkit systemd zenity`

`kdialog` can replace `zenity` if you prefer KDE-native dialogs for prompts.

Install with the bundled installer:

```bash
./install.sh
```

By default this installs under `/usr/local`.

Useful install options:

```bash
./install.sh --prefix /usr/local
./install.sh --no-polkit
./install.sh --uninstall
```

If you prefer native packaging:

- Arch: `packaging/arch/PKGBUILD`
- Fedora: `packaging/fedora/restart-to-macos.spec`
- Homebrew tap: `brew install jtbrough/tap/restart-to-macos`

Homebrew is a convenience path, not the primary Linux packaging target. It still
depends on distro-provided `asahi-bless`, `polkit`, `systemd`, and `zenity` or
`kdialog`.

## Use

Check the installed setup:

```bash
restart-to-macos --check
```

Run the launcher:

```bash
restart-to-macos
```

The launcher:

- checks that the required helper and host dependencies exist
- prompts for confirmation through `zenity` or `kdialog`
- runs `asahi-bless --next --set-boot-macos`
- reboots immediately

Remove a manual install later with:

```bash
restart-to-macos-uninstall
```

Or:

```bash
./install.sh --uninstall
```

## Development

Main local tasks:

```bash
just lint
just validate
just test
just ci
just build-arch
just build-fedora
just prepare-release
```

Task breakdown:

- `just lint`: `shellcheck` and `actionlint`
- `just validate`: rendered desktop entry validation and polkit XML validation
- `just test`: staged install and health-check tests
- `just ci`: local equivalent of the main CI lint/validate/test flow
- `just build-arch`: Arch package smoke build
- `just build-fedora`: Fedora RPM smoke build
- `just prepare-release`: update the Arch release checksum from the GitHub tag tarball

For native package builds, the installer also supports:

```bash
./install.sh --destdir /path/to/stage --prefix /usr --package-build
```

`--package-build` skips the self-managed uninstall command and manifest files so
native package managers remain the sole source of truth for installed files.

Staged tests cover:

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
