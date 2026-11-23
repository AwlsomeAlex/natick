Name:           natick-disk
Version:        0.0.1
Release:        1%{?dist}
Summary:        Configuration for the natickOS disk profile
License:        ISC
URL:            https://github.com/AwlsomeAlex/natick
Source0:        fstab
Source1:        serial.conf
Source2:        LICENSE
BuildArch:      noarch
Conflicts:      natick-initramfs

Requires:       finit

%description
Root filesystem and Finit serial console configuration for the natickOS disk image.

%install
install -D -m 0644 "%{SOURCE0}" "%{buildroot}/etc/fstab"
install -D -m 0644 "%{SOURCE1}" "%{buildroot}/etc/finit.d/serial.conf"
install -D -m 0644 "%{SOURCE2}" "%{buildroot}%{_licensedir}/%{name}/LICENSE"

%files
%license %{_licensedir}/%{name}/LICENSE
%config(noreplace) /etc/fstab
%config(noreplace) /etc/finit.d/serial.conf

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 0.0.1-1
- Initial port of natick-disk from BTR to spec file

