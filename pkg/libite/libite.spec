# Skip automatic debuginfo subpackages for cross-build
%global debug_package %{nil}

Name:           libite
Version:        2.6.2
Release:        1%{?dist}
Summary:        Lightweight utility library for C
License:        MIT AND ISC AND BSD-2-Clause AND BSD-3-Clause
URL:            https://github.com/troglobit/libite
Source0:        https://github.com/troglobit/libite/releases/download/v%{version}/libite-%{version}.tar.xz

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache

%description
A collection of utility functions for C programs.

%package devel
Summary:        Development files for libite
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Headers, the linker symlink, and pkg-config metadata for libite.

%prep
%autosetup

%build
./configure \
    --build="$(CC_FOR_BUILD="$HOSTCC" sh ./aux/config.guess)" \
    --host="$NATICK_TARGET" \
    --prefix=/usr \
    --libdir=%{_libdir} \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --enable-shared \
    --disable-static \
    --disable-doxygen-doc \
    CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    STRIP="$STRIP"

make %{?_smp_mflags} -C src

%install
make -C src DESTDIR="%{buildroot}" install
rm -f -- "%{buildroot}%{_libdir}/libite.la"

%files
%license LICENSE
%{_libdir}/libite.so.*

%files devel
/usr/include/libite/
/usr/include/lite
%{_libdir}/libite.so
%{_libdir}/pkgconfig/libite.pc

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 2.6.2-1
- Initial port of libite from BTR to spec file
