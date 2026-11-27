# Skip automatic debuginfo subpackages for cross-build
%global debug_package %{nil}

Name:           pkgconf
Version:        3.0.11
Release:        1%{?dist}
Summary:        Package compiler and linker metadata toolkit
License:        ISC
URL:            https://github.com/pkgconf/pkgconf
Source0:        https://github.com/pkgconf/pkgconf/releases/download/pkgconf-%{version}/pkgconf-%{version}.tar.xz

BuildRequires:  natick-host-meson
BuildRequires:  natick-host-ninja
BuildRequires:  natick-host-ccache

%description
Package compiler and linker metadata toolkit

%package -n lib%{name}
Summary:        libpkgconf shared library

%description -n lib%{name}
pkgconf shared library

%package -n lib%{name}-devel
Summary:        Development files for libpkgconf
Requires:       lib%{name}%{?_isa} = %{version}-%{release}

%description -n lib%{name}-devel
Headers, the linker symlink, and pkg-config metadata for libpkgconf.

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

meson setup build --cross-file=cross.ini --buildtype=release \
    --prefix=%{_prefix} --bindir=%{_bindir} --sbindir=%{_sbindir} --libdir=%{_libdir} \
    --default-library=shared
meson compile -C build %{?_smp_mflags}

%install
DESTDIR="%{buildroot}" meson install -C build --no-rebuild
ln -s pkgconf "%{buildroot}%{_bindir}/pkg-config"

# Remove undesired binaries + manpages
rm -f -- "%{buildroot}%{_bindir}"/{bomtool,spdxtool,pccritic} \
    "%{buildroot}%{_mandir}/man1"/{bomtool,spdxtool,pccritic}.1

# Packaged from source tree with %doc and %license instead
rm -rf -- "%{buildroot}%{_datadir}/doc/pkgconf"

%files
%license COPYING
%doc AUTHORS README.md
%{_bindir}/%{name}
%{_bindir}/pkg-config
%{_mandir}/man1/pkgconf.1*
%{_mandir}/man5/pc.5*
%{_mandir}/man5/pkgconf-personality.5*

%files -n lib%{name}
%license COPYING
%{_libdir}/libpkgconf.so.*

%files -n lib%{name}-devel
%{_includedir}/pkgconf/
%{_libdir}/libpkgconf.so
%{_libdir}/pkgconfig/libpkgconf.pc
%{_datadir}/aclocal/pkg.m4
%{_mandir}/man7/pkg.m4.7*

%changelog
* Thu Nov 26 2026 Alexander Barris <alex@awlsome.com> - 3.0.11-1
- Initial natickOS package of pkgconf (libpkgconf and libpkgconf-devel)
