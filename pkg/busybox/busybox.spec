# Skip automatic debuginfo subpackages for cross-build
%global debug_package %{nil}

# Standalone packages own these commands by default
%bcond init_applets 0
%bcond kmod_applets 0
%bcond xz_applets 0

%global busybox_make %{shrink:
    make ARCH=%{_target_cpu}
    CROSS_COMPILE=
    CC="ccache $CC --target=$NATICK_TARGET"
    HOSTCC="$HOSTCC"
    AR="$AR"
    NM="$NM"
    STRIP="$STRIP"
    OBJCOPY="$OBJCOPY"
    OBJDUMP="$OBJDUMP"
    CONFIG_SYSROOT="$NATICK_SYSROOT"
}

Name:           busybox
Version:        1.38.0
Release:        2%{?dist}
Summary:        BusyBox is an implementation of many Unix commands in a single executable file
License:        GPL-2.0-only
URL:            https://busybox.net
Source0:        https://busybox.net/downloads/busybox-%{version}.tar.bz2
Source1:        disable-init-applets.sed
Source2:        disable-kmod-applets.sed
Source3:        disable-xz-applets.sed
Patch0:         0001-tc-guard-obsolete-cbq.patch
Patch1:         0002-detect-clang-with-compiler-arguments.patch

BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache
BuildRequires:  natick-host-bzip2

%description
BusyBox is an implementation of many Unix commands in a single executable file

%prep
%autosetup -p1

%build
%{busybox_make} defconfig

# Enable Static Linking
sed -i \
    's/^# CONFIG_STATIC is not set$/CONFIG_STATIC=y/' \
    .config

# Disable explicit GCC runtime
sed -i \
    's/^CONFIG_STATIC_LIBGCC=y$/# CONFIG_STATIC_LIBGCC is not set/' \
    .config

# 'init'-related things are delivered by finit
%if %{without init_applets}
sed -i -f "%{SOURCE1}" .config
%endif
# 'kmod'-related things are delivered by kmod
%if %{without kmod_applets}
sed -i -f "%{SOURCE2}" .config
%endif
# 'xz'-related things are delivered by xz and xz-lmza
%if %{without xz_applets}
sed -i -f "%{SOURCE3}" .config
%endif

%{busybox_make} oldconfig

grep -qx 'CONFIG_STATIC=y' .config

%{busybox_make} %{?_smp_mflags} busybox
%{busybox_make} busybox.links

%install
install -d "%{buildroot}/usr/bin" "%{buildroot}/usr/sbin"
install -m 0755 busybox "%{buildroot}/usr/bin/busybox"

sort -u busybox.links > applets.list
while IFS= read -r applet; do
    case "$applet" in
        /linuxrc) continue ;;
        /bin/*|/sbin/*) applet="/usr$applet" ;;
    esac

    case "$applet" in
        /usr/bin/*)  link=busybox ;;
        /usr/sbin/*) link=../bin/busybox ;;
        *) echo "Unexpected BusyBox applet path: $applet" >&2; exit 1 ;;
    esac

    ln -s "$link" "%{buildroot}$applet"
done < applets.list

%files
%license LICENSE
/usr/bin/*
/usr/sbin/*

%changelog
* Thu Nov 26 2026 Alexander Barris <alex@awlsome.com> - 1.38.0-2
- Disable init, kernel module, and XZ/LZMA applets by default; build switches to re-enable

* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 1.38.0-1
- Initial port of busybox from BTR to spec file
