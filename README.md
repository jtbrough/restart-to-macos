# restart-to-macos

Cross-desktop launcher for Asahi Linux users who want a one-time restart into macOS.

<p align="center">
<img width="75%" alt="restart to macos hero screenshot" src="https://github.com/user-attachments/assets/64596872-47f6-4138-a089-614a50e588df" />
</p>

## Contents

- [Disclaimer](#disclaimer)
- [Install](#install)
- [Use](#use)
- [Development](#development)

## Disclaimer
One could, of course, just do this via simple CLI:
```bash
asahi-bless --next --set-boot-macos -y && systemctl reboot
```
I built this small app because:
1. it was fun.
2. I wanted to learn a bit about Linux packaging.
3. I like the way it works. 
  
If you decide to use it, I hope you enjoy it. Please feel free to report any issues.

## Install

### Dependencies
There is really only one dependency a typically system might not have: `asahi-bless`. 

If `restart-to-macos --check` reports missing `asahi-bless`:

- Fedora Asahi: `sudo dnf install asahi-bless`
- Arch/Asahi ALARM: `sudo pacman -S asahi-bless`

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

## Use

### Via CLI

```bash
restart-to-macos --check
OK: helper found at /usr/libexec/restart-to-macos-helper
OK: asahi-bless found at /usr/bin/asahi-bless
OK: pkexec found at /usr/bin/pkexec
OK: systemctl found at /usr/bin/systemctl
OK: kdialog found for GUI prompts
OK: desktop file found at /usr/share/applications/restart-to-macos.desktop
OK: system application directory is in use (/usr/share/applications)

restart-to-macos --version
0.1.6

restart-to-macos
```

### Via GUI

Launching via Application Launcher:

<p align="center">
<img width="75%" alt="restart to macos via app launcher" src="https://github.com/user-attachments/assets/5cad4e1d-7e6a-4b62-a266-ef56cbd13f78" />
</p>

Launching via KRunner:

<p align="center">
<img width="75%" alt="restart to macos via krunner" src="https://github.com/user-attachments/assets/5f24b9c9-daf0-419d-8a60-5d2c741357cf" />
</p>

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
