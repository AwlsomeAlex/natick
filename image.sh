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
    echo "  --target ARCH ==> (x86_64/aarch64)"
    echo "  --overwrite   ==> Overwrite existing image"
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
    mkdir -p -- \
        "$ROOTFS_DIR/usr/bin" \
        "$ROOTFS_DIR/usr/sbin" \
        "$ROOTFS_DIR/usr/lib" \
        "$ROOTFS_DIR/dev" \
        "$ROOTFS_DIR/proc" \
        "$ROOTFS_DIR/sys" \
        "$ROOTFS_DIR/run" \
        "$ROOTFS_DIR/tmp" \
        "$ROOTFS_DIR/etc" \
        "$ROOTFS_DIR/root" \
        "$ROOTFS_DIR/var/lib/finit" \
        "$ROOTFS_DIR/var/log" \
        "$ROOTFS_DIR/var/tmp" \
        "$IMAGE_DIR"

    chmod 1777 "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/var/tmp"
    chmod 700 "$ROOTFS_DIR/root"

    ln -s usr/bin "$ROOTFS_DIR/bin"
    ln -s usr/sbin "$ROOTFS_DIR/sbin"
    ln -s usr/lib "$ROOTFS_DIR/lib"
    ln -s ../run "$ROOTFS_DIR/var/run"
    ln -s ../proc/mounts "$ROOTFS_DIR/etc/mtab"
)

package_archive_path() (
    local requested=$1
    local name='' version='' release=''
    local -a patches=() bld_deps=()

    local recipe="$RECIPE_DIR/$requested/$requested.btr"

    [[ -f "$recipe" ]] \
        || die "Recipe missing: $requested"

    source "$recipe" >&2 \
        || die "Cannot read recipe: $requested"

    printf '%s/%s-%s-%s.%s.tar.zst\n' \
        "$PKG_DIR" "$name" "$version" "$release" "$TARGET"
)

install_package() (
    local archive=$1
    local temporary
    local directory

    temporary=$(mktemp -d "$IMAGE_DIR/package.XXXXXX") \
        || die "Cannot create package extraction directory"

    trap 'rm -rf -- "$temporary"' EXIT

    echo "[....] Installing ${archive##*/}"
    tar --zstd \
        --extract \
        --no-same-owner \
        --file="$archive" \
        --directory="$temporary" \
        || die "Cannot extract package: $archive"

    for directory in bin sbin lib; do
        [[ ! -L "$temporary/$directory" ]] \
            || die "Unexpected package directory symlink: $directory"

        if [[ -d "$temporary/$directory" ]]; then
            cp -a -- "$temporary/$directory/." \
                "$ROOTFS_DIR/usr/$directory/" \
                || die "Cannot merge package directory: $directory"

            rm -rf -- "$temporary/$directory"
        fi
    done

    cp -a -- "$temporary/." "$ROOTFS_DIR/" \
        || die "Cannot install package contents: $archive"
)

# ----- Core Functions ----- #

assemble_rootfs() (
    local -a packages=(natick-base busybox musl libite libuev finit natick-milestone1)
    local -a archives=()
    local package archive
    local command

    # Check every required archive before replacing an existing rootfs.
    for package in "${packages[@]}"; do
        archive=$(package_archive_path "$package") \
            || die "Cannot locate package: $package"

        [[ -f "$archive" ]] \
            || die "Package archive missing: $archive"

        archives+=("$archive")
    done

    prepare_rootfs

    for archive in "${archives[@]}"; do
        install_package "$archive"
    done

    # Finit supplies PID 1 and the shutdown commands
    ln -sfn finit "$ROOTFS_DIR/usr/sbin/init"
    ln -sfn finit "$ROOTFS_DIR/usr/sbin/telinit"

    for command in reboot shutdown halt poweroff suspend; do
        ln -sfn initctl "$ROOTFS_DIR/usr/sbin/$command"
    done

    # Restore filesystem policy after package directory modes are copied.
    chmod 1777 "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/var/tmp"
    chmod 700 "$ROOTFS_DIR/root"
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
    x86_64)
        export TARGET="x86_64-linux-musl"
        export LINUX_ARCH="x86"
        ;;
    aarch64)
        export TARGET="aarch64-linux-musl"
        export LINUX_ARCH="arm64"
        ;;
    *)
        die "Unsupported target: $target"
        ;;
esac

export SYSROOT_DIR="${BUILDROOT}/${TARGET}/sysroot"

export RECIPE_DIR="${SCRIPT_DIR}/pkg"
export PKG_DIR="${OUTPUT_DIR}/${TARGET}/packages"

export IMAGE_DIR="${OUTPUT_DIR}/${TARGET}/images"
export ROOTFS_DIR="${OUTPUT_DIR}/${TARGET}/rootfs"

case $subcommand in
    build)
        assemble_rootfs
        build_initramfs
        ;;
    clean)
        rm -rf -- "$ROOTFS_DIR" "$IMAGE_DIR" \
            || die "Cannot remove image output"
        ;;
esac
