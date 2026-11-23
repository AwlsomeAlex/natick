Name:           natick-base
Version:        0.0.1
Release:        1%{?dist}
Summary:        Base configuration and identity files for natickOS
License:        ISC
URL:            https://github.com/AwlsomeAlex/natick
Source0:        os-release
Source1:        passwd
Source2:        group
Source3:        LICENSE
BuildArch:      noarch

%description
Base account files, filesystem configuration, and OS identity for natickOS.

%install
install -D -m 0644 "%{SOURCE0}" "%{buildroot}/usr/lib/os-release"
install -D -m 0644 "%{SOURCE1}" "%{buildroot}/etc/passwd"
install -D -m 0644 "%{SOURCE2}" "%{buildroot}/etc/group"
ln -s ../usr/lib/os-release "%{buildroot}/etc/os-release"
install -D -m 0644 "%{SOURCE3}" "%{buildroot}%{_licensedir}/%{name}/LICENSE"

%files
%license %{_licensedir}/%{name}/LICENSE
%config(noreplace) /etc/group
%config(noreplace) /etc/passwd
/etc/os-release
/usr/lib/os-release

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 0.0.1-1
- Initial port of natick-base from BTR to spec file
