Name:           libuev
Version:        2.4.1
Release:        1%{?dist}
Summary:        Linux event-loop library
License:        MIT
URL:            https://github.com/troglobit/libuev
Source0:        https://github.com/troglobit/libuev/releases/download/v%{version}/libuev-%{version}.tar.xz

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache

%description
Linux event-loop library

%package devel
Summary:        Development files for libuev
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Headers, the linker symlink, and pkg-config metadata for libuev.

%prep
%autosetup

%build
%natick_configure \
    --enable-shared \
    --disable-static \
    --disable-doxygen-doc

%make_build -C src libuev.la

#./configure \
#    --build="%{natick_build}" \
#    --host="$NATICK_TARGET" \
#    --prefix=/usr \
#    --libdir=%{_libdir} \
#    --sysconfdir=/etc \
#    --localstatedir=/var \
#    --enable-shared \
#    --disable-static \
#    --disable-doxygen-doc \
#    CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT" \
#    AR="$AR" \
#    RANLIB="$RANLIB" \
#    STRIP="$STRIP"

#make %{?_smp_mflags} -C src libuev.la

%install
%make_install -C src noinst_PROGRAMS=
#make -C src noinst_PROGRAMS= DESTDIR="%{buildroot}" install
rm -f -- "%{buildroot}%{_libdir}/libuev.la"

%files
%license LICENSE
%{_libdir}/libuev.so.*

%files devel
/usr/include/uev/
%{_libdir}/libuev.so
%{_libdir}/pkgconfig/libuev.pc

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 2.4.1-1
- Initial port of libuev from BTR to spec file
