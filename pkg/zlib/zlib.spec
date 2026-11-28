Name:           zlib
Version:        1.4
Release:        1%{?dist}
Summary:        A Massively Spiffy Yet Delicately Unobtrusive Compression Library
License:        Zlib
URL:            https://zlib.net/
Source0:        https://zlib.net/zlib-%{version}.tar.xz

BuildRequires:  natick-host-cmake
BuildRequires:  natick-host-ninja
BuildRequires:  natick-host-ccache
BuildRequires:  natick-host-pkg-config

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
%natick_cmake -DZLIB_BUILD_SHARED=ON -DZLIB_BUILD_STATIC=OFF -DZLIB_BUILD_TESTING=OFF
%natick_cmake_build

%install
%natick_cmake_install
# Keep the existing payload; CMake exports can introduce a cmake-filesystem requirement.
rm -rf -- "%{buildroot}%{_libdir}/cmake/zlib" "%{buildroot}%{_docdir}/zlib"

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
