# Skip automatic debuginfo subpackages for cross-build
%global debug_package %{nil}

Name:           openssl
Version:        4.1.0
Release:        1%{?dist}
Summary:        General purpose TLS and crypto library
License:        Apache-2.0
URL:            https://openssl-library.org
Source0:        https://github.com/openssl/openssl/releases/download/openssl-%{version}/openssl-%{version}.tar.gz

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache
BuildRequires:  natick-host-perl

%description
General purpose TLS and crypto library

%package libs
Summary:        OpenSSL libraries

%description libs
OpenSSL libraries

%package devel
Summary:        Development files for openssl
Requires:       %{name}-libs%{?_isa} = %{version}-%{release}

%description devel
Headers, the linker symlink, and pkg-config metadata for openssl.

%prep
%autosetup

%build
case "$NATICK_TARGET" in
    x86_64-linux-musl) openssl_target=linux-x86_64 ;;
    aarch64-linux-musl) openssl_target=linux-aarch64 ;;
    *) echo "Unsupported OpenSSL target: $NATICK_TARGET" >&2; exit 1 ;;
esac

CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT" \
    AR="$AR" RANLIB="$RANLIB" \
    perl Configure "$openssl_target" shared no-tests no-docs \
    no-fips no-legacy no-module \
    --prefix=%{_prefix} --libdir=%{_libdir} --openssldir=%{_sysconfdir}/ssl

make %{?_smp_mflags}

%install
make DESTDIR="%{buildroot}" install_sw
install -D -m 0644 apps/openssl.cnf \
    "%{buildroot}%{_sysconfdir}/ssl/openssl.cnf"
install -d -m 0755 "%{buildroot}%{_sysconfdir}/ssl/certs"
rm -f -- "%{buildroot}%{_libdir}"/{libcrypto,libssl}.a

# TODO: Drop cmake until we can provide cmake-filesystem
rm -rf -- %{buildroot}%{_libdir}/cmake/OpenSSL

%files
%license LICENSE.txt
%{_bindir}/openssl

%files libs
%license LICENSE.txt
%{_libdir}/libcrypto.so.4*
%{_libdir}/libssl.so.4*
%dir %{_sysconfdir}/ssl
%dir %{_sysconfdir}/ssl/certs
%config(noreplace) %{_sysconfdir}/ssl/openssl.cnf

%files devel
%{_includedir}/openssl/
%{_libdir}/libcrypto.so
%{_libdir}/libssl.so
%{_libdir}/pkgconfig/libcrypto.pc
%{_libdir}/pkgconfig/libssl.pc
%{_libdir}/pkgconfig/openssl.pc
# TODO: Drop cmake until we can provide cmake-filesystem
#%{_libdir}/cmake/OpenSSL/

%changelog
* Thu Nov 26 2026 Alexander Barris <alex@awlsome.com> - 4.1.0-1
- Initial natickOS package of openssl (openssl-libs, openssl-devel)
