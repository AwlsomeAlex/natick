Name:           zstd
Version:        1.6.0
Release:        1%{?dist}
Summary:        Zstandard - Fast real-time compression algorithm
License:        BSD-3-Clause OR GPL-2.0-only
URL:            https://meta.github.io/zstd/
Source0:        https://github.com/meta/zstd/releases/download/v%{version}/zstd-%{version}.tar.gz

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache
# TODO: lz4, xz and zlib
#BuildRequires:  lz4-devel
#BuildRequires:  xz-devel
#BuildRequires:  zlib-devel

%description
Zstandard - Fast real-time compression algorithm.

%package -n lib%{name}
Summary:        libzstd shared library

%description -n lib%{name}
zstd shared library

%package -n lib%{name}-devel
Summary:        Development files for libzstd
Requires:       lib%{name}%{?_isa} = %{version}-%{release}

%description -n lib%{name}-devel
Headers, the linker symlink, and pkg-config metadata for libzstd.

%prep
%autosetup

%build
%natick_make_build -C lib libzstd-release
%natick_make_build -C programs \
    HAVE_ZLIB=0 HAVE_LZMA=0 HAVE_LZ4=0 zstd-release

%install
# Shared library and development headers
%natick_make_destdir -C lib \
    PREFIX="%{_prefix}" LIBDIR="%{_libdir}" INCLUDEDIR="%{_includedir}" \
    install-shared install-includes install-pc

# Binaries (including aliases) but not the grep/less helper script
%natick_make_destdir -C programs \
    BINDIR="%{_bindir}" MAN1DIR="%{_mandir}/man1" install
rm -f -- "%{buildroot}%{_bindir}"/{zstdgrep,zstdless} \
    "%{buildroot}%{_mandir}/man1"/{zstdgrep,zstdless}.1

%files
%license LICENSE COPYING
%{_bindir}/%{name}
%{_bindir}/unzstd
%{_bindir}/zstdcat
%{_bindir}/zstdmt
%{_mandir}/man1/zstd.1*
%{_mandir}/man1/unzstd.1*
%{_mandir}/man1/zstdcat.1*

%files -n lib%{name}
%license LICENSE COPYING
%{_libdir}/libzstd.so.*

%files -n lib%{name}-devel
%{_includedir}/zstd.h
%{_includedir}/zstd_errors.h
%{_includedir}/zdict.h
%{_libdir}/libzstd.so
%{_libdir}/pkgconfig/libzstd.pc

%changelog
* Thu Nov 26 2026 Alexander Barris <alex@awlsome.com> - 1.6.0-1
- Initial natickOS package of zstd (libzstd and libzstd-devel)
