Name:           xz
Version:        5.8.4
Release:        1%{?dist}
Summary:        XZ Utils
License:        0BSD
URL:            https://tukaani.org/xz/
Source0:        https://github.com/tukaani-project/xz/releases/download/v%{version}/xz-%{version}.tar.xz

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache

%description
Command line tools for XZ and LZMA compressed files

%package -n %{name}-lzma
Summary:        LZMA Utils emulation with XZ Utils
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description -n %{name}-lzma
LZMA Utils emulation with XZ Utils

%package -n liblzma
Summary:        Library for XZ and LZMA compressed files

%description -n liblzma
Library for XZ and LZMA compressed files

%package -n liblzma-devel
Summary:        Development files for liblzma
Requires:       liblzma%{?_isa} = %{version}-%{release}

%description -n liblzma-devel
Headers, the linker symlink, and pkg-config metadata for liblzma.

%prep
%autosetup

%build
%natick_configure \
    --enable-shared \
    --disable-static \
    --disable-scripts \
    --disable-doc \
    --disable-nls

%make_build

#./configure \
#    --build="%{natick_build}" \
#    --host="$NATICK_TARGET" \
#    --prefix=%{_prefix} \
#    --libdir=%{_libdir} \
#    --sysconfdir=%{_sysconfdir} \
#    --localstatedir=%{_localstatedir} \
#    --disable-scripts \
#    --disable-doc \
#    --disable-static \
#    --disable-nls \
#    --enable-shared \
#    CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT" \
#    AR="$AR" \
#    RANLIB="$RANLIB" \
#    STRIP="$STRIP"

#make %{?_smp_mflags}

%install
%make_install
#make DESTDIR="%{buildroot}" install-strip
rm -f -- "%{buildroot}%{_libdir}/liblzma.la"

%files
%license COPYING COPYING.0BSD
%{_bindir}/xz
%{_bindir}/unxz
%{_bindir}/xzcat
%{_bindir}/xzdec
%{_mandir}/man1/xz.1*
%{_mandir}/man1/unxz.1*
%{_mandir}/man1/xzcat.1*
%{_mandir}/man1/xzdec.1*

%files -n %{name}-lzma
%{_bindir}/lzma
%{_bindir}/unlzma
%{_bindir}/lzcat
%{_bindir}/lzmadec
%{_bindir}/lzmainfo
%{_mandir}/man1/lzma.1*
%{_mandir}/man1/unlzma.1*
%{_mandir}/man1/lzcat.1*
%{_mandir}/man1/lzmadec.1*
%{_mandir}/man1/lzmainfo.1*

%files -n liblzma
%license COPYING COPYING.0BSD
%{_libdir}/liblzma.so.5*

%files -n liblzma-devel
%{_includedir}/lzma.h
%{_includedir}/lzma/
%{_libdir}/liblzma.so
%{_libdir}/pkgconfig/liblzma.pc

%changelog
* Thu Nov 26 2026 Alexander Barris <alex@awlsome.com> - 5.8.4-1
- Initial natickOS package of xz (xz-lzma, liblzma and liblzma-devel)
