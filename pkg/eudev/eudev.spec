Name:           eudev
Version:        3.3.0
Release:        1%{?dist}
Summary:        Linux device manager and libudev
License:        GPL-2.0-only AND GPL-2.0-or-later AND LGPL-2.0-or-later AND LGPL-2.1-or-later AND BSD-3-Clause AND MIT AND CC0-1.0
URL:            https://github.com/eudev-project/eudev
Source0:        https://github.com/eudev-project/eudev/releases/download/v%{version}/eudev-%{version}.tar.gz
Source1:        udevd

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache
BuildRequires:  natick-host-gperf
BuildRequires:  natick-host-pkg-config
BuildRequires:  pkgconfig(libkmod) >= 15
BuildRequires:  pkgconfig(blkid) >= 2.20

%description
Linux device manager with the udev daemon, device rules, hardware database
sources, and the libudev shared library.

%package devel
Summary:        Development files for libudev
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Header, linker symlink, and pkg-config metadata for eudev and libudev.

%prep
%autosetup

%build
%natick_configure \
    --libexecdir=%{_libdir} \
    --enable-shared \
    --disable-static \
    --enable-blkid \
    --enable-kmod \
    --disable-selinux \
    --disable-manpages \
    --with-system-uid-max=999 \
    --with-system-gid-max=999 \
    --with-bashcompletiondir=no \
    --with-zshcompletiondir=no

%make_build

#./configure \
#    --build="%{natick_build}" \
#    --host="$NATICK_TARGET" \
#    --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
#    --libdir=%{_libdir} --libexecdir=%{_libdir} \
#    --sysconfdir=/etc --localstatedir=/var --runstatedir=/run \
#    --enable-shared --disable-static \
#    --enable-blkid --enable-kmod --disable-selinux --disable-manpages \
#    --with-system-uid-max=999 --with-system-gid-max=999 \
#    --with-bashcompletiondir=no --with-zshcompletiondir=no \
#    CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT"

#make %{?_smp_mflags}

%install
%make_install
#make DESTDIR="%{buildroot}" install
rm -f -- "%{buildroot}%{_libdir}/libudev.la"
install -D -m 0644 "%{SOURCE1}" "%{buildroot}/etc/default/udevd"

%files
%license COPYING LICENSES/
%config(noreplace) /etc/default/udevd
%dir /etc/udev
%config(noreplace) /etc/udev/udev.conf
/usr/bin/udevadm
/usr/bin/systemd-hwdb
/usr/sbin/udevd
%{_libdir}/libudev.so.*
%{_libdir}/udev/

%files devel
/usr/include/libudev.h
%{_libdir}/libudev.so
%{_libdir}/pkgconfig/libudev.pc
/usr/share/pkgconfig/udev.pc

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 3.3.0-1
- Initial port from BTR to spec file
