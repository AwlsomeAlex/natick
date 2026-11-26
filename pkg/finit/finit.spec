# Skip automatic debuginfo subpackages for cross-build
%global debug_package %{nil}

Name:           finit
Version:        4.17
Release:        1%{?dist}
Summary:        Init and service supervisor for natickOS
License:        MIT
URL:            https://github.com/troglobit/finit
Source0:        https://github.com/troglobit/finit/releases/download/%{version}/finit-%{version}.tar.gz
Source1:        finit.conf
Source2:        logging.conf
Patch0:         0001-cgroup-include-sm-header.patch
Patch1:         0002-conf-include-sm-header.patch
Patch2:         0003-preserve-boot-console.patch

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache
BuildRequires:  natick-host-pkg-config
BuildRequires:  pkgconfig(libite) >= 2.6.1
BuildRequires:  pkgconfig(libuev) >= 2.4.1
Requires:       /usr/sbin/syslogd
Requires:       /usr/sbin/klogd

%description
Init and service supervisor for natickOS.

%package devel
Summary:        Development headers for Finit plugins
Requires:       %{name}%{?_isa} = %{version}-%{release}
Requires:       libite-devel%{?_isa} >= 2.6.1
Requires:       libuev-devel%{?_isa} >= 2.4.1

%description devel
Headers for building plugins for Finit.

%prep
%autosetup -p1

%build
./configure \
    --build="$(CC_FOR_BUILD="$HOSTCC" sh ./aux/config.guess)" \
    --host="$NATICK_TARGET" \
    --prefix=/usr \
    --bindir=%{_bindir} \
    --sbindir=%{_sbindir} \
    --libdir=%{_libdir} \
    --libexecdir=%{_libdir} \
    --sysconfdir=%{_sysconfdir} \
    --localstatedir=%{_localstatedir} \
    --runstatedir=%{_runstatedir} \
    --enable-auto-reload \
    --disable-doc \
    --disable-contrib \
    --disable-libcap \
    --without-keventd \
    --without-sulogin \
    --without-watchdog \
    --without-libsystemd \
    --with-bash-completion-dir=no \
    --with-heading="natickOS" \
    --with-hostname=natickos \
    --with-random-seed=%{_sharedstatedir}/finit/random-seed \
    CC="ccache $CC --target=$NATICK_TARGET --sysroot=$NATICK_SYSROOT" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    STRIP="$STRIP"

make %{?_smp_mflags}

%install
make DESTDIR="%{buildroot}" install
rm -f -- "%{buildroot}%{_docdir}/finit/LICENSE"
install -D -m 0644 "%{SOURCE1}" "%{buildroot}%{_sysconfdir}/finit.conf"
install -D -m 0644 "%{SOURCE2}" "%{buildroot}%{_sysconfdir}/finit.d/logging.conf"
install -d -m 0755 "%{buildroot}%{_sysconfdir}/finit.d/available" \
                   "%{buildroot}%{_sharedstatedir}/finit"

%files
%license LICENSE
%doc %{_docdir}/finit/README.md
%doc %{_docdir}/finit/finit.conf

%config(noreplace) %{_sysconfdir}/finit.conf
%dir %{_sysconfdir}/finit.d
%config(noreplace) %{_sysconfdir}/finit.d/logging.conf
%dir %{_sysconfdir}/finit.d/available
%dir %{_sharedstatedir}/finit

%{_libdir}/finit/
%{_libdir}/tmpfiles.d/*.conf

%{_sbindir}/finit
%{_sbindir}/initctl
%{_sbindir}/init
%{_sbindir}/telinit
%{_sbindir}/halt
%{_sbindir}/poweroff
%{_sbindir}/reboot
%{_sbindir}/shutdown
%{_sbindir}/suspend

%{_mandir}/man5/finit.conf.5*
%{_mandir}/man8/finit.8*
%{_mandir}/man8/initctl.8*

%files devel
%{_includedir}/finit/

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 4.17-1
- Initial port of finit from BTR to spec file
