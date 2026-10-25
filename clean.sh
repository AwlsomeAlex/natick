#!/bin/bash
set -euo pipefail

die() {
    printf '[FAIL] %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" \
    || die "Cannot determine script directory"

(($# == 1)) \
    || die "Usage: ${0##*/} x86_64|aarch64|all|purge"

clean_target() {
    local target=$1

    echo "[....] Removing all outputs for $target"

    rm -rf -- \
        "$SCRIPT_DIR/build/$target" \
        "$SCRIPT_DIR/out/$target" \
        || die "Cannot clean target: $target"
}

case "$1" in
    x86_64)
        clean_target x86_64-linux-musl
        ;;
    aarch64)
        clean_target aarch64-linux-musl
        ;;
    all)
        clean_target x86_64-linux-musl
        clean_target aarch64-linux-musl
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