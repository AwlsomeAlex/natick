# Skip automatic debuginfo subpackages for cross-build
%global debug_package %{nil}

Name:           musl
Version:        1.2.6
Release:        1%{?dist}
Summary:        C standard library
License:        MIT
URL:            https://musl.libc.org
Source0:        https://musl.libc.org/releases/musl-%{version}.tar.gz
Patch0:         0001-slowness-mapping-icov.patch

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache

Provides:       rtld(GNU_HASH)

%description
C standard library

%package devel
Summary:        Development files for musl libc
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
Headers, the linker symlink, and pkg-config metadata for musl libc.

%prep
%autosetup -p1

%build
builtins=$("$CC" --target="$NATICK_TARGET" --sysroot="$NATICK_SYSROOT" \
    --rtlib=compiler-rt --print-libgcc-file-name)
test -s "$builtins" || { echo "Compiler-rt builtins missing: $builtins" >&2; exit 1; }

./configure \
    --target="$NATICK_TARGET" \
    --prefix=/usr \
    --libdir=%{_libdir} \
    --syslibdir=%{_libdir} \
    --disable-gcc-wrapper \
    CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT --ld-path=$NATICK_TOOLCHAIN/bin/ld.lld" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    LIBCC="$builtins"

make %{?_smp_mflags}

%install
make DESTDIR="%{buildroot}" install

# musl's install rule tolerates symlink creation failures
ln -sfn libc.so "%{buildroot}%{_libdir}/ld-musl-%{_target_cpu}.so.1"

%files
%license COPYRIGHT
%{_libdir}/libc.so
%{_libdir}/ld-musl-%{_target_cpu}.so.1

%files devel
/usr/include/*
%{_libdir}/*.a
%{_libdir}/*crt*.o

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 1.2.6-1
- Initial port of musl from BTR to spec file