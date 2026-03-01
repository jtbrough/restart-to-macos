# restart-to-macos

Cross-desktop launcher for Asahi Linux users who want a one-time restart into macOS.

## Disclaimer
One could, of course, just do this via simple CLI:
```bash
asahi-bless --next --set-boot-macos -y && systemctl reboot
```
I built this small app because 1) it was fun. 2) I wanted to learn about Linux packaging. 3) I like the way it works.

## Install

### Brew

Install:

```bash
brew tap jtbrough/tap
brew install jtbrough/tap/restart-to-macos
```

Uninstall:

```bash
brew uninstall restart-to-macos
```

Brew also installs a launcher symlink in `~/.local/share/applications`.

### Arch

Install:

```bash
curl -LO https://github.com/jtbrough/restart-to-macos/releases/latest/download/restart-to-macos.pkg.tar.zst
sudo pacman -U ./restart-to-macos.pkg.tar.zst
```

Uninstall:

```bash
sudo pacman -Rns restart-to-macos
```

### Fedora

Install:

```bash
curl -LO https://github.com/jtbrough/restart-to-macos/releases/latest/download/restart-to-macos.noarch.rpm
sudo dnf install ./restart-to-macos.noarch.rpm
```

Uninstall:

```bash
sudo dnf remove restart-to-macos
```

### Manual

Install:

```bash
git clone https://github.com/jtbrough/restart-to-macos.git
cd restart-to-macos
./install.sh
```

Uninstall:

```bash
sudo /usr/local/bin/restart-to-macos-uninstall
```

Manual installs via `install.sh` create a user-local launcher entry and remove it on uninstall.

If `restart-to-macos --check` reports missing `asahi-bless`:

- Fedora Asahi: `sudo dnf install asahi-bless`
- Arch/Asahi Arch: `sudo pacman -S asahi-bless`

## Use

```bash
restart-to-macos --check
restart-to-macos
```

## Development

Project layout:

- `src/`: installable payload
- `packaging/`: Arch, Fedora, and Brew packaging
- `tests/`: test suite
- `tools/`: release and validation helpers

```bash
just lint
just validate
just test
just ci
just build-arch
just build-fedora
just prepare-release
```
