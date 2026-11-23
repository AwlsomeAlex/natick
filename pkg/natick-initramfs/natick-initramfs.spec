Name:           natick-initramfs
Version:        0.0.1
Release:        1%{?dist}
Summary:        Early init and configuration for the natickOS initramfs profile
License:        ISC
URL:            https://github.com/AwlsomeAlex/natick
Source0:        init
Source1:        serial.conf
Source2:        fstab
Source3:        LICENSE
BuildArch:      noarch
Conflicts:      natick-disk

Requires:       finit

%description
Early init, an empty fstab template, and Finit serial console configuration
for the natickOS RAM-backed image.

%install
install -D -m 0755 "%{SOURCE0}" "%{buildroot}/init"
install -D -m 0644 "%{SOURCE1}" "%{buildroot}/etc/finit.d/serial.conf"
install -D -m 0644 "%{SOURCE2}" "%{buildroot}/etc/fstab"
install -D -m 0644 "%{SOURCE3}" "%{buildroot}%{_licensedir}/%{name}/LICENSE"

%files
%license %{_licensedir}/%{name}/LICENSE
/init
%config(noreplace) /etc/fstab
%config(noreplace) /etc/finit.d/serial.conf

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 0.0.1-1
- Initial port of natick-initramfs from BTR to spec file
