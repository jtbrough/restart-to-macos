# restart-to-macos

Cross-desktop launcher for Asahi Linux users who want a one-time restart into macOS.

## Install

### Brew

```bash
brew tap jtbrough/tap
brew install jtbrough/tap/restart-to-macos
```

### Arch

```bash
curl -LO https://github.com/jtbrough/restart-to-macos/releases/latest/download/restart-to-macos.pkg.tar.zst
sudo pacman -U ./restart-to-macos.pkg.tar.zst
```

### Fedora

```bash
curl -LO https://github.com/jtbrough/restart-to-macos/releases/latest/download/restart-to-macos.noarch.rpm
sudo dnf install ./restart-to-macos.noarch.rpm
```

If `restart-to-macos --check` reports missing `asahi-bless`:

- Fedora Asahi: `sudo dnf install asahi-bless`
- Arch/Asahi Arch: `sudo pacman -S asahi-bless`

## Use

```bash
restart-to-macos --check
restart-to-macos
```

## Development

```bash
just lint
just validate
just test
just ci
just build-arch
just build-fedora
just prepare-release
```
