%ifarch x86_64
%global kbuild_arch x86
%endif
%ifarch aarch64
%global kbuild_arch arm64
%endif

%define linux_make %{shrink:env -u PKG_CONFIG_SYSROOT_DIR -u PKG_CONFIG_LIBDIR -u PKG_CONFIG_PATH \
    %{__make} ARCH=%{kbuild_arch} LOCALVERSION= \
    %{?natick_cross:LLVM="$NATICK_TOOLCHAIN/bin/" CC="ccache $CC" HOSTCC="$HOSTCC" HOSTCXX="$HOSTCXX"} \
    %{!?natick_cross:LLVM=1}}

Name:           linux
Version:        7.3.4
Release:        1%{?dist}
Summary:        The Linux kernel
License:        GPL-2.0-only WITH Linux-syscall-note
URL:            https://kernel.org
Source0:        https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-%{version}.tar.xz

BuildRequires:  natick-host-bc
BuildRequires:  natick-host-bison
BuildRequires:  natick-host-flex
BuildRequires:  natick-host-pkg-config
BuildRequires:  natick-host-depmod
BuildRequires:  natick-host-make
BuildRequires:  natick-host-ccache

%description
The Linux kernel

%prep
%autosetup

%build
case "%{kbuild_arch}" in
    x86)   defconfig=x86_64_defconfig; image_target=bzImage ;;
    arm64) defconfig=defconfig;        image_target=Image ;;
esac

%{linux_make} "$defconfig"

scripts/config \
    --set-str DEFAULT_HOSTNAME natickOS \
    --set-str LOCALVERSION "-%{release}.%{_target_cpu}" \
    --disable LOCALVERSION_AUTO \
    --enable BLOCK \
    --enable BLK_DEV \
    --enable VIRTIO_MENU \
    --enable VIRTIO_BLK \
    --enable EXT4_FS \
    --enable DEVTMPFS \
    --enable DEVTMPFS_MOUNT

case "%{kbuild_arch}" in
    x86)   scripts/config --enable PCI --enable VIRTIO_PCI --disable NETFILTER_XT_TARGET_TCPMSS ;;
    arm64) scripts/config --disable COMPAT --enable VIRTIO_MMIO ;;
esac

%{linux_make} olddefconfig
grep -qx 'CONFIG_MODULES=y' .config
%{linux_make} %{_smp_mflags} "$image_target" modules

%install
case "%{kbuild_arch}" in
    x86)   image_path=arch/x86/boot/bzImage ;;
    arm64) image_path=arch/arm64/boot/Image ;;
esac

kernel_release=$(%{linux_make} -s kernelrelease)

install -D -m 0644 "$image_path" "%{buildroot}/boot/vmlinuz-$kernel_release"
install -D -m 0644 .config "%{buildroot}/boot/config-$kernel_release"
install -D -m 0644 System.map "%{buildroot}/boot/System.map-$kernel_release"

%{linux_make} INSTALL_MOD_PATH="%{buildroot}" INSTALL_MOD_STRIP=1 modules_install
rm -f -- "%{buildroot}/lib/modules/$kernel_release/build" \
          "%{buildroot}/lib/modules/$kernel_release/source"
test -s "%{buildroot}/lib/modules/$kernel_release/modules.dep.bin"

install -d "%{buildroot}/usr/lib"
mv "%{buildroot}/lib/modules" "%{buildroot}/usr/lib/modules"
rmdir "%{buildroot}/lib"

%files
%license COPYING LICENSES/preferred/GPL-2.0 LICENSES/exceptions/Linux-syscall-note
/boot/vmlinuz-*
/boot/config-*
/boot/System.map-*
/usr/lib/modules/

%changelog
* Sun Nov 22 2026 Alexander Barris <alex@awlsome.com> - 7.3.4
- Initial port of linux from BTR to spec file
