Name:           natick-filesystem
Version:        0.0.1
Release:        1%{?dist}
Summary:        Base filesystem layout for natickOS
License:        ISC
URL:            https://github.com/AwlsomeAlex/natick
Source0:        LICENSE
BuildArch:      noarch

%description
Shared directories, their permissions, and merged-/usr compatibility links
for natickOS.

%install
install -d -m 0755 \
    "%{buildroot}/boot" "%{buildroot}/dev" "%{buildroot}/etc" \
    "%{buildroot}/proc" "%{buildroot}/run" "%{buildroot}/sys" \
    "%{buildroot}/usr/bin" "%{buildroot}/usr/lib" \
    "%{buildroot}/usr/sbin" "%{buildroot}/usr/share" \
    "%{buildroot}/var/lib" "%{buildroot}/var/log"
install -d -m 0700 "%{buildroot}/root"
install -d -m 1777 "%{buildroot}/tmp" "%{buildroot}/var/tmp"

ln -s usr/bin "%{buildroot}/bin"
ln -s usr/sbin "%{buildroot}/sbin"
ln -s usr/lib "%{buildroot}/lib"
ln -s ../run "%{buildroot}/var/run"
ln -s ../proc/mounts "%{buildroot}/etc/mtab"

install -D -m 0644 "%{SOURCE0}" "%{buildroot}%{_licensedir}/%{name}/LICENSE"

%files
%license %{_licensedir}/%{name}/LICENSE
/bin
/sbin
/lib
/var/run
/etc/mtab
%dir /boot
%dir /dev
%dir /etc
%dir /proc
%dir %attr(0700,root,root) /root
%dir /run
%dir /sys
%dir %attr(1777,root,root) /tmp
%dir /usr
%dir /usr/bin
%dir /usr/lib
%dir /usr/sbin
%dir /usr/share
%dir /var
%dir /var/lib
%dir /var/log
%dir %attr(1777,root,root) /var/tmp

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 0.0.1-1
- Package the shared filesystem layout and compatibility symlinks
