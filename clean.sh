#!/bin/bash
set -euo pipefail

die() {
    printf '[FAIL] %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" \
    || die "Cannot determine script directory"

(($# == 1)) \
    || die "Usage: ${0##*/} x86_64|aarch64|toolchain|all|purge"

clean_target() {
    local target=$1

    echo "[....] Removing all outputs for $target"

    rm -rf -- \
        "$SCRIPT_DIR/build/$target" \
        "$SCRIPT_DIR/build/rpm/$target" \
        "$SCRIPT_DIR/out/$target" \
        || die "Cannot clean target: $target"
}

clean_shared_toolchain() {
    echo "[....] Removing shared LLVM installation and build directory"

    rm -rf -- "$SCRIPT_DIR/build/toolchain" "$SCRIPT_DIR/build/llvm-work" \
        || die "Cannot clean shared toolchain"
}

case "$1" in
    x86_64)
        clean_target x86_64-linux-musl
        ;;
    aarch64)
        clean_target aarch64-linux-musl
        ;;
    toolchain)
        clean_shared_toolchain
        ;;
    all)
        clean_target x86_64-linux-musl
        clean_target aarch64-linux-musl
        clean_shared_toolchain
        ;;
    purge)
        echo "[....] Removing all outputs, downloads, and compiler cache"

        rm -rf -- "$SCRIPT_DIR/build" "$SCRIPT_DIR/out" \
            || die "Cannot purge generated directories"
        ;;
    *)
        die "Unknown cleanup scope: $1"
        ;;
esac