%global debug_package %{nil}

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
cat > cross.ini <<EOF
[binaries]
c = ['ccache', '$CC', '--target=$NATICK_TARGET', '--sysroot=$NATICK_SYSROOT']
ar = '$AR'
strip = '$STRIP'
pkg-config = 'pkg-config'

[host_machine]
system = 'linux'
cpu_family = '%{_target_cpu}'
cpu = '%{_target_cpu}'
endian = 'little'

[properties]
needs_exe_wrapper = true
sys_root = '$NATICK_SYSROOT'
pkg_config_libdir = ['$NATICK_SYSROOT/usr/lib/pkgconfig', '$NATICK_SYSROOT/usr/share/pkgconfig']
EOF

# TODO: Enable compression libraries and OpenSSL once packaged for natickOS.
meson setup build --cross-file=cross.ini --buildtype=release \
    --prefix=/usr --bindir=bin --sbindir=sbin --libdir=%{_libdir} \
    --sysconfdir=/etc --localstatedir=/var --default-library=shared \
    -Dzlib=enabled -Dxz=enabled -Dzstd=enabled -Dopenssl=enabled \
    -Dmanpages=false -Ddocs=false \
    -Dbashcompletiondir=no -Dfishcompletiondir=no -Dzshcompletiondir=no \
    -Dtools=true
meson compile -C build %{?_smp_mflags}

%install
DESTDIR="%{buildroot}" meson install -C build --no-rebuild

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
