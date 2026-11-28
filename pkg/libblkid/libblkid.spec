Name:           libblkid
Version:        2.42.4
Release:        1%{?dist}
Summary:        Block device identification library
License:        LGPL-2.1-or-later
URL:            https://github.com/util-linux/util-linux
Source0:        https://www.kernel.org/pub/linux/utils/util-linux/v2.42/util-linux-%{version}.tar.xz

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache
BuildRequires:  natick-host-pkg-config

%description
Library for identifying filesystems and other metadata on block devices.

%package devel
Summary:        Development files for libblkid
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Headers, the linker symlink, and pkg-config metadata for libblkid.

%prep
%autosetup -n util-linux-%{version}

%build
%natick_configure \
    --enable-shared \
    --disable-static \
    --disable-all-programs \
    --enable-libblkid \
    --disable-asciidoc \
    --disable-gtk-doc \
    --disable-nls \
    --disable-bash-completion \
    --without-python \
    --without-systemd \
    --without-udev \
    --without-econf

%make_build

#./configure \
#    --build="%{natick_build}" \
#    --host="$NATICK_TARGET" \
#    --prefix=/usr \
#    --libdir=%{_libdir} \
#    --sysconfdir=/etc \
#    --localstatedir=/var \
#    --enable-shared \
#    --disable-static \
#    --disable-all-programs \
#    --enable-libblkid \
#    --disable-asciidoc \
#    --disable-gtk-doc \
#    --disable-nls \
#    --disable-bash-completion \
#    --without-python \
#    --without-systemd \
#    --without-udev \
#    --without-econf \
#    CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT" \
#    AR="$AR" \
#    RANLIB="$RANLIB" \
#    STRIP="$STRIP"

#make %{?_smp_mflags}

%install
%make_install
#make DESTDIR="%{buildroot}" install
rm -f -- "%{buildroot}%{_libdir}/libblkid.la"
rm -f -- "%{buildroot}%{_mandir}/man5/terminal-colors.d.5"*

%files
%license libblkid/COPYING
%license Documentation/licenses/COPYING.LGPL-2.1-or-later
%{_libdir}/libblkid.so.*

%files devel
/usr/include/blkid/
%{_libdir}/libblkid.so
%{_libdir}/pkgconfig/blkid.pc
%{_mandir}/man3/libblkid.3*

%changelog
* Thu Nov 19 2026 Alexander Barris <alex@awlsome.com> - 2.42.4-1
- Initial port of libblkid from BTR to spec file