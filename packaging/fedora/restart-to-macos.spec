Name:           restart-to-macos
Version:        0.1.2
Release:        1%{?dist}
Summary:        One-time restart into macOS for Asahi Linux systems

License:        MIT
URL:            https://github.com/jtbrough/restart-to-macos
Source0:        %{url}/releases/download/v%{version}/%{name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       asahi-bless
Requires:       polkit
Requires:       systemd
Recommends:     zenity
Recommends:     kdialog

%description
restart-to-macos installs a launcher, helper, and polkit policy for Asahi
Linux users who want a one-time restart into macOS from a graphical desktop.

%prep
%autosetup -n %{name}-%{version}

%build

%install
./install.sh --destdir %{buildroot} --prefix %{_prefix} --package-build

%files
%license LICENSE
%doc README.md
%{_bindir}/restart-to-macos
%{_libexecdir}/restart-to-macos-helper
%{_datadir}/applications/restart-to-macos.desktop
%{_datadir}/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy

%changelog
* Sat Feb 28 2026 Jordan Brough <jtbrough@users.noreply.github.com> - 0.1.2-1
- Initial package
