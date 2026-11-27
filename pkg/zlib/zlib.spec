# Skip automatic debuginfo subpackages for cross-build
%global debug_package %{nil}

Name:           zlib
Version:        1.4
Release:        1%{?dist}
Summary:        A Massively Spiffy Yet Delicately Unobtrusive Compression Library
License:        Zlib
URL:            https://zlib.net/
Source0:        https://zlib.net/zlib-%{version}.tar.xz

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache

%description
A Massively Spiffy Yet Delicately Unobtrusive Compression Library

%package -n %{name}-devel
Summary:        Development files for zlib
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description -n %{name}-devel
Headers, the linker symlink, and pkg-config metadata for zlib.

%prep
%autosetup

%build
CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT" \
    AR="$AR" RANLIB="$RANLIB" NM="$NM" \
    ./configure --shared --prefix=%{_prefix} \
    --libdir=%{_libdir} \
    --includedir=%{_includedir} --mandir=%{_mandir}

make %{?_smp_mflags}

%install
make DESTDIR="%{buildroot}" install
rm -f -- "%{buildroot}%{_libdir}/libz.a"

%files
%license LICENSE
%{_libdir}/libz.so.1*

%files -n %{name}-devel
%{_includedir}/zlib.h
%{_includedir}/zconf.h
%{_libdir}/libz.so
%{_libdir}/pkgconfig/zlib.pc
%{_mandir}/man3/zlib.3*

%changelog
* Thu Nov 26 2026 Alexander Barris <alex@awlsome.com> - 1.4-1
- Initial natickOS package of zlib (zlib-devel)
