Name:           kmod
Version:        34
Release:        2%{?dist}
Summary:        Linux kernel module utilities and library
License:        GPL-2.0-or-later AND LGPL-2.1-or-later
URL:            https://github.com/kmod-project/kmod
Source0:        https://github.com/kmod-project/kmod/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  natick-host-meson
BuildRequires:  natick-host-ninja
BuildRequires:  natick-host-pkg-config
BuildRequires:  natick-host-ccache
BuildRequires:  pkgconfig(liblzma) >= 4.99
BuildRequires:  pkgconfig(libzstd) >= 1.4.4
BuildRequires:  pkgconfig(zlib)
BuildRequires:  pkgconfig(libcrypto) >= 1.1.0

%description
Utilities for managing Linux kernel modules, and the libkmod shared library.

%package devel
Summary:        Development files for libkmod
License:        LGPL-2.1-or-later
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Header, linker symlink, and pkg-config metadata for libkmod.

%prep
%autosetup

%build
%natick_meson --default-library=shared \
    -Dzlib=enabled -Dxz=enabled -Dzstd=enabled -Dopenssl=enabled \
    -Dmanpages=false -Ddocs=false \
    -Dbashcompletiondir=no -Dfishcompletiondir=no -Dzshcompletiondir=no \
    -Dtools=true
%natick_meson_build

%install
%natick_meson_install

%files
%license COPYING
/usr/bin/kmod
/usr/sbin/depmod
/usr/sbin/insmod
/usr/sbin/lsmod
/usr/sbin/modinfo
/usr/sbin/modprobe
/usr/sbin/rmmod
%{_libdir}/libkmod.so.*
%dir /etc/depmod.d
%dir /etc/modprobe.d
%dir /usr/lib/depmod.d
%dir /usr/lib/modprobe.d

%files devel
/usr/include/libkmod.h
%{_libdir}/libkmod.so
%{_libdir}/pkgconfig/libkmod.pc
/usr/share/pkgconfig/kmod.pc

%changelog
* Thu Nov 26 2026 Alexander Barris <alex@awlsome.com> - 34-2
- Enable OpenSSL, XZ, zstd, and zlib module support

* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 34-1
- Initial port from BTR to spec file
