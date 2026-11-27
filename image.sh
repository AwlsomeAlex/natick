#!/bin/bash

# --------
# natickOS - Image Script
# --------
# ISC License
# Copyright (C) 2017-2026 Alexander Barris
# All Rights Reserved
set -eou pipefail

export EXEC="${0##*/}"

die() {
    echo "[FAIL] $*" >&2
    exit 1
}

# Basic Directory Structure
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" \
    || die "Cannot determine script directory"
export BUILDROOT="${SCRIPT_DIR}/build"
export OUTPUT_DIR="${SCRIPT_DIR}/out"

# ----- Helper Functions ----- #

usage() {
    echo "natickOS image script - vGIT"
    echo ""
    echo "Usage:"
    echo "  ${EXEC} (COMMAND) [option]"
    echo "COMMAND:"
    echo "  build ==> Build image"
    echo "  clean ==> Clean image"
    echo "  help  ==> Shows this message"
    echo ""
    echo "build option:"
    echo "  --target ARCH  ==> x86_64/aarch64"
    echo "  --profile NAME ==> initramfs/disk (default: initramfs)"
    echo "  --overwrite    ==> Overwrite existing image"
    echo ""
    echo "natickOS: <https://github.com/awlsomealex/natick>"
}

prepare_rootfs() (
    umask 022

    if [[ -e "$ROOTFS_DIR" || -L "$ROOTFS_DIR" ]]; then
        (( overwrite == 1 )) \
            || die "Root filesystem exists: $ROOTFS_DIR; use --overwrite"

        rm -rf -- "$ROOTFS_DIR" \
            || die "Cannot remove previous root filesystem"
    fi

    echo "[....] Preparing root filesystem"
    mkdir -p -- "$ROOTFS_DIR" "$IMAGE_DIR"
)

package_rpm_path() (
    local requested=$1
    local name arch filename outputs archive
    local spec="$RECIPE_DIR/$requested/$requested.spec"
    local top="$BUILDROOT/rpm/$TARGET/$requested"

    [[ -f "$spec" ]] || die "Spec missing: $spec"
    outputs=$(rpmspec --target "${TARGET%%-*}" --define "_topdir $top" \
        "${natick_rpm_defs[@]}" -q --rpms \
        --qf '%{NAME} %{ARCH} %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm\n' "$spec") \
        || die "Cannot query RPM outputs: $spec"
    while read -r name arch filename; do
        [[ "$name" == "$requested" ]] || continue
        [[ "$arch" == "${TARGET%%-*}" || "$arch" == noarch ]] || continue
        archive="$top/RPMS/$arch/$filename"
        [[ -f "$archive" ]] || die "Runtime RPM missing: $archive
Build it first: ./build.sh build --target ${TARGET%%-*} --package $requested"
        printf '%s\n' "$archive"
        return
    done <<< "$outputs"
    die "No runtime RPM for $requested ($TARGET)"
)

install_package() (
    local archive=$1
    local temporary

    temporary=$(mktemp -d "$IMAGE_DIR/package.XXXXXX") \
        || die "Cannot create package extraction directory"

    trap 'rm -rf -- "$temporary"' EXIT

    echo "[....] Installing ${archive##*/}"
    rpm2cpio "$archive" | (
        cd -- "$temporary"
        cpio -idm --quiet --no-absolute-filenames --no-preserve-owner
    ) || die "Cannot extract RPM: $archive"

    # Copy payload entries, not the private extraction directory's mode.
    shopt -s dotglob nullglob
    local -a entries=("$temporary"/*)
    if (( ${#entries[@]} )); then
        cp -a -- "${entries[@]}" "$ROOTFS_DIR/" \
            || die "Cannot install package contents: $archive"
    fi
)

# ----- Core Functions ----- #

assemble_rootfs() (
    local -a archives=()
    local package archive tool

    for tool in rpmspec rpm2cpio cpio; do
        command -v "$tool" >/dev/null || die "Missing host command: $tool"
    done
    source "$SCRIPT_DIR/rpm/defines.sh"

    # Check every required RPM before replacing an existing rootfs.
    for package in "${image_packages[@]}"; do
        archive=$(package_rpm_path "$package") || exit 1
        archives+=("$archive")
    done

    prepare_rootfs

    for archive in "${archives[@]}"; do
        install_package "$archive"
    done
)

build_initramfs() (
    local output="$IMAGE_DIR/initramfs.cpio.gz"

    local temporary
    temporary=$(mktemp "${output}.tmp.XXXXXX") \
        || die "Cannot create temporary initramfs"
    trap 'rm -f -- "$temporary"' EXIT

    echo "[....] Creating initramfs...."
    cd -- "$ROOTFS_DIR" \
        || die "Cannot enter root filesystem"

    find . -print0 |
        LC_ALL=C sort -z |
        cpio --null --create --format=newc \
            --owner=0:0 --reproducible |
        gzip -n > "$temporary" \
        || die "Cannot create initramfs"

    chmod 644 "$temporary"
    mv -f -- "$temporary" "$output" \
        || die "Cannot finalize initramfs"
)

build_ext4() (
    local output="$IMAGE_DIR/rootfs.ext4"
    local temporary

    if [[ -e "$output" || -L "$output" ]]; then
        (( overwrite == 1 )) \
            || die "Disk image exists: $output; use --overwrite"
    fi

    temporary=$(mktemp "${output}.tmp.XXXXXX") \
        || die "Cannot create temporary disk image"
    trap 'rm -f -- "$temporary"' EXIT

    echo "[....] Creating ext4 root filesystem...."
    truncate -s 1G "$temporary" \
        || die "Cannot size disk image"

    fakeroot -- bash -eou pipefail -c '
        chown -hR 0:0 -- "$1"

        mke2fs \
            -t ext4 \
            -F \
            -b 4096 \
            -m 0 \
            -L natick-root \
            -E root_owner=0:0 \
            -d "$1" \
            "$2"
    ' bash "$ROOTFS_DIR" "$temporary" \
        || die "Cannot populate ext4 image"

    chmod 644 "$temporary" \
        || die "Cannot populate ext4 image"

    mv -f -- "$temporary" "$output" \
        || die "Cannot finalize disk image"
)

prepare_efi() (
    local platform bootfile console
    local modules_dir kernel
    local temporary
    local -a kernels

    case "$TARGET" in
        x86_64-linux-musl)
            platform=x86_64-efi
            bootfile=BOOTX64.EFI
            console=ttyS0
            ;;
        aarch64-linux-musl)
            platform=arm64-efi
            bootfile=BOOTAA64.EFI
            console=ttyAMA0
            ;;
        *)
            die "Unsupported EFI target: $TARGET"
            ;;
    esac

    modules_dir="/usr/lib/grub/$platform"
    [[ -f "$modules_dir/modinfo.sh" ]] \
        || die "GRUB platform modules missing: $platform"

    shopt -s nullglob
    kernels=("$ROOTFS_DIR"/boot/vmlinuz-*)
    (( ${#kernels[@]} == 1 )) \
        || die "Expected exactly one installed kernel"
    kernel=${kernels[0]##*/}

    mkdir -p -- \
        "$ROOTFS_DIR/boot/grub" \
        "$IMAGE_DIR/efi/EFI/BOOT"

    temporary=$(mktemp -d "$IMAGE_DIR/grub.XXXXXX") \
        || die "Cannot create GRUB work directory"
    trap 'rm -rf -- "$temporary"' EXIT

    cat > "$ROOTFS_DIR/boot/grub/grub.cfg" <<EOF
set default=0
set timeout=5

menuentry "natickOS" {
    linux /boot/$kernel console=$console,115200 root=/dev/vda2 rootfstype=ext4 rootwait ro init=/sbin/init
}
EOF

    cat > "$temporary/early.cfg" <<'EOF'
search --no-floppy --label natick-root --set=root
set prefix=($root)/boot/grub
EOF

    echo "[....] Creating $platform EFI bootloader...."
    grub2-mkimage \
        -O "$platform" \
        -d "$modules_dir" \
        -p /boot/grub \
        -c "$temporary/early.cfg" \
        -o "$temporary/$bootfile" \
        part_gpt fat ext2 normal linux search search_label \
        || die "EFI bootloader generation failed"

    install -m 644 "$temporary/$bootfile" \
        "$IMAGE_DIR/efi/EFI/BOOT/$bootfile" \
        || die "Cannot install EFI bootloader"
)

build_esp() (
    local output="$IMAGE_DIR/esp.fat"
    local temporary

    if [[ -e "$output" || -L "$output" ]]; then
        (( overwrite == 1 )) \
            || die "EFI partition image exists; use --overwrite"
    fi

    temporary=$(mktemp "${output}.tmp.XXXXXX") \
        || die "Cannot create temporary EFI partition image"
    trap 'rm -f -- "$temporary"' EXIT

    echo "[....] Creating EFI system partition...."
    truncate -s 128M "$temporary" \
        || die "Cannot size EFI partition image"

    mkfs.fat -F 32 -n NATICK_EFI "$temporary" \
        || die "Cannot format EFI partition image"

    mcopy -i "$temporary" -s "$IMAGE_DIR/efi/EFI" ::/ \
        || die "Cannot copy EFI boot files"

    chmod 644 "$temporary" \
        || die "Cannot set EFI partition image permissions"

    mv -f -- "$temporary" "$output" \
        || die "Cannot finalize EFI partition image"
)

build_disk() (
    local output="$IMAGE_DIR/natick.img"
    local esp="$IMAGE_DIR/esp.fat"
    local rootfs="$IMAGE_DIR/rootfs.ext4"
    local temporary
    local esp_bytes root_bytes
    local esp_start esp_end root_start root_end disk_bytes

    if [[ -e "$output" || -L "$output" ]]; then
        (( overwrite == 1 )) \
            || die "Disk image exists; use --overwrite"
    fi

    esp_bytes=$(stat -c %s -- "$esp") \
        || die "Cannot determine EFI partition size"

    root_bytes=$(stat -c %s -- "$rootfs") \
        || die "Cannot determine root partition size"

    # Partition calculations use 512-byte sectors.
    (( esp_bytes > 0 && root_bytes > 0 &&
       esp_bytes % 512 == 0 && root_bytes % 512 == 0 )) \
        || die "Partition images must contain whole sectors"

    # Start partitions on 1 MiB boundaries
    esp_start=2048
    esp_end=$((esp_start + esp_bytes / 512 - 1))
    root_start=$(((esp_end + 1 + 2047) / 2048 * 2048))
    root_end=$((root_start + root_bytes / 512 - 1))

    # Leave space after the root partition for the backup GPT.
    disk_bytes=$(((root_end + 1 + 2048) * 512))

    temporary=$(mktemp "${output}.tmp.XXXXXX") \
        || die "Cannot create temporary disk image"
    trap 'rm -f -- "$temporary"' EXIT

    echo "[....] Creating GPT disk image...."
    truncate -s "$disk_bytes" "$temporary" \
        || die "Cannot size disk image"

    sfdisk "$temporary" <<EOF || die "Cannot create partition table"
label: gpt
unit: sectors

start=$esp_start, size=$((esp_bytes / 512)), type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI"
start=$root_start, size=$((root_bytes / 512)), type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="natick-root"
EOF

    dd if="$esp" of="$temporary" \
        bs=1M seek="$((esp_start / 2048))" \
        conv=notrunc,sparse status=progress \
        || die "Cannot write EFI partition"

    dd if="$rootfs" of="$temporary" \
        bs=1M seek="$((root_start / 2048))" \
        conv=notrunc,sparse status=progress \
        || die "Cannot write root partition"

    sfdisk --verify "$temporary" \
        || die "Disk partition verification failed"

    chmod 644 "$temporary" \
        || die "Cannot set disk image permissions"

    mv -f -- "$temporary" "$output" \
        || die "Cannot finalize disk image."
)

# ----- Execution ----- #
(($#)) || { usage >&2; exit 1; }

subcommand=$1
shift

case $subcommand in
    build|clean) ;;
    help) usage; exit 0 ;;
    *) die "unknown command: $subcommand" ;;
esac

target=''
overwrite=0
profile=initramfs
while (($#)); do
    case $1 in
        --target)
            if (($# < 2)) || [[ $2 == -* ]]; then
                die "--target requires a value"
            fi
            target=$2
            shift 2
            ;;
        --target=*)
            target=${1#*=}
            shift
            ;;
        --profile)
            if (($# < 2)) || [[ $2 == -* ]]; then
                die "--profile requires a value"
            fi
            profile=$2
            shift 2
            ;;
        --profile=*)
            profile=${1#*=}
            shift
            ;;
        --overwrite)
            overwrite=1
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            die "unknown option: $1"
            ;;
        *)
            die "unexpected argument: $1"
            ;;
    esac
done

if [[ ${target} == '' ]]; then
    die "No target specified."
fi

case "$target" in
    x86_64|aarch64) ;;
    *) die "Unsupported target: $target" ;;
esac
export TARGET="${target}-linux-musl"

image_packages=(natick-filesystem natick-base busybox musl libite libuev finit)
case "$profile" in
    initramfs)
        image_packages+=(natick-initramfs)
        ;;
    disk)
        image_packages+=(linux kmod libblkid eudev natick-disk)
        ;;
    *)
        die "Unsupported image profile: $profile"
        ;;
esac

export RECIPE_DIR="${SCRIPT_DIR}/pkg"

export IMAGE_DIR="${OUTPUT_DIR}/${TARGET}/${profile}/images"
export ROOTFS_DIR="${OUTPUT_DIR}/${TARGET}/${profile}/rootfs"

case $subcommand in
    build)
        assemble_rootfs
        case "$profile" in
            initramfs)
                build_initramfs
                ;;
            disk)
                prepare_efi
                build_esp
                build_ext4
                build_disk
                ;;
        esac
        ;;
    clean)
        rm -rf -- "$ROOTFS_DIR" "$IMAGE_DIR" \
            || die "Cannot remove image output"
        ;;
esac
