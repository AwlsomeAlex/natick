#!/bin/bash

# --------
# natickOS - Toolchain Script
# --------
# ISC License
# Copyright (C) 2017-2026 Alexander Barris
# All Rights Reserved
set -eou pipefail

export EXEC="${0##*/}"

# Toolchain Versions
LLVM_VER="23.1.3"
LINUX_VER="6.18.57"
MUSL_VER="1.2.6"

die() {
    echo "[FAIL] $*" >&2
    exit 1
}

# Basic Directory Structure
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" \
    || die "Cannot determine script directory"
export ROOT="${SCRIPT_DIR}/build"
export SOURCES="${ROOT}/src"

# ----- Helper Functions ----- #

usage() {
    echo "natickOS toolchain script - vGIT"
    echo ""
    echo "Usage:"
    echo "  ${EXEC} (COMMAND) [option]"
    echo "COMMAND:"
    echo "  build ==> Build toolchain"
    echo "  clean ==> Clean toolchain"
    echo "  help  ==> Shows this message"
    echo ""
    echo "build option:"
    echo "  --target ARCH ==> (x86_64/aarch64)"
    echo "  --overwrite   ==> Overwrite existing toolchain"
    echo ""
    echo "natickOS: <https://github.com/awlsomealex/natick>"
}

depcheck() {
    jq_ver=$(jq --version 2>/dev/null) || die "Missing jq utility!"
    clang_ver=$(clang -dumpversion 2>/dev/null) || die "Missing clang compiler!"
    lld_ver=$(ld.lld --version | awk '{ for (i = 1; i < NF; i++) if ($i == "LLD") { print $(i + 1); exit } }') || die "Missing LLD linker!"
    llvm_ver=$(llvm-config --version 2>/dev/null) || die "Missing LLVM compiler backend!"
    cmake_ver=$(cmake -E capabilities | jq -r '.version.string') || die "Missing cmake build tool!"
    ninja_ver=$(ninja --version) || die "Missing ninja build system!"
    git_ver=$(git --version) || die "Missing git version control system!"
    git_ver=${git_ver#git version }
    curl_ver=$(curl --version | awk 'NR == 1 { print $2 }') || die "Missing curl!"
    xz_ver=$(xz --version | awk 'NR == 1 { print $NF }') || die "Missing xz!"
    python_ver=$(python3 --version | awk '{ print $2 }') || die "Missing Python 3!"
    pkgconf_ver=$(pkg-config --version) || die "Missing pkg-config!"
    echo "----"
    echo "    Clang ${clang_ver} (LLVM ${llvm_ver}, LLD ${lld_ver})"
    echo "        with CMake ${cmake_ver} / Ninja ${ninja_ver}"
    echo "    Git ${git_ver}, cURL ${curl_ver}, XZ ${xz_ver}, Python ${python_ver}"
    echo "    pkg-config ${pkgconf_ver}"
    echo "----"
    echo "[DONE] All dependencies met."
}

fetch_source() {
    local url=$1
    local archive=$2
    local dir=$3

    [[ -d "$dir" ]] && return 0

    if [[ ! -f "$archive" ]]; then
        echo "[....] Downloading $archive"
        curl -fL --retry 3 --progress-bar \
            -o "${archive}.part" "$url" \
            || die "Download failed: $archive"
        mv "${archive}.part" "$archive"
    fi

    echo "[....] Extracting $archive"
    tar -xf "$archive" || die "Extraction failed: ${archive}"
}

# ---- Core Functions ---- #

prep() {
    if [[ -d "$BUILD" ]] || [[ -d "$BOOTSTRAP" ]] || [[ -d "$SYSROOT" ]]; then
        ((overwrite == 0)) && die "Existing toolchain found. Exiting...."
        echo "[....] Cleaning existing toolchain...."
        rm -rf "$BUILD" "$BOOTSTRAP" "$SYSROOT"
    fi
    mkdir -p "$SOURCES" "$BUILD" "$BOOTSTRAP" "$SYSROOT"
    echo "[DONE] Directories ready."
}

download() {
    cd "$SOURCES"

    if [[ ! -d llvm-project ]]; then
        git clone \
            --progress \
            --depth 1 \
            --branch "llvmorg-${LLVM_VER}" \
            https://github.com/llvm/llvm-project.git \
            || die "LLVM clone failed"
    fi

    fetch_source \
        "https://cdn.kernel.org/pub/linux/kernel/v${LINUX_VER%%.*}.x/linux-${LINUX_VER}.tar.xz" \
        "linux-${LINUX_VER}.tar.xz" \
        "linux-${LINUX_VER}"
    
    fetch_source \
        "https://musl.libc.org/releases/musl-${MUSL_VER}.tar.gz" \
        "musl-${MUSL_VER}.tar.gz" \
        "musl-${MUSL_VER}"
}

llvm_stage0() {
    echo "[....] Configuring Clang/LLVM...."
    cmake -S "$SOURCES/llvm-project/llvm" \
          -B "$BUILD/llvm-stage0" \
          -G Ninja \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_C_COMPILER=clang \
          -DCMAKE_CXX_COMPILER=clang++ \
          -DCMAKE_INSTALL_PREFIX="$BOOTSTRAP" \
          -DLLVM_ENABLE_PROJECTS="clang;lld" \
          -DLLVM_TARGETS_TO_BUILD="$llvm_target" \
          -DLLVM_USE_LINKER=lld \
          -DLLVM_ENABLE_ASSERTIONS=OFF \
          -DLLVM_INCLUDE_TESTS=OFF \
          -DLLVM_INCLUDE_EXAMPLES=OFF \
          -DLLVM_INCLUDE_BENCHMARKS=OFF \
          -DLLVM_ENABLE_LIBEDIT=OFF \
          -DLLVM_ENABLE_LIBXML2=OFF \
          -DLLVM_ENABLE_ZLIB=OFF \
          -DLLVM_ENABLE_ZSTD=OFF

    echo "[....] Building Clang/LLVM...."
    cmake --build "$BUILD/llvm-stage0" --parallel \
        || die "Clang/LLVM stage 0 build failed"
    cmake --install "$BUILD/llvm-stage0" \
        || die "Clang/LLVM stage 0 installation failed"
}

sysroot_headers() (
    echo "[....] Exporting Linux kernel headers...."
    make -C "$SOURCES/linux-${LINUX_VER}" \
        ARCH="$linux_target" \
        INSTALL_HDR_PATH="$SYSROOT/usr" \
        headers_install \
        || die "Kernel headers installation failed"

    mkdir -p "$BUILD/musl"
    cd "$BUILD/musl" || die "Cannot enter musl build directory"

    echo "[....] Configuring musl...."
    "$SOURCES/musl-${MUSL_VER}/configure" \
        --target="$TARGET" \
        --prefix=/usr \
        --syslibdir=/lib \
        --disable-gcc-wrapper \
        CC="$BOOTSTRAP/bin/clang --target=$TARGET --sysroot=$SYSROOT -fuse-ld=lld" \
        || die "musl configuration failed"

    echo "[....] Exporting musl headers...." 
    make DESTDIR="$SYSROOT" install-headers \
        || die "musl header installation failed"
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

case $target in
    x86_64)
        triple_target="x86_64"
        llvm_target="X86"
        linux_target="x86"
        ;;
    aarch64)
        triple_target="aarch64"
        llvm_target="AArch64"
        linux_target="arm64"
        ;;
    *) die "Unsupported target: $target" ;;
esac
export TARGET="${triple_target}-linux-musl"
export BUILD="${ROOT}/${TARGET}/work"
export BOOTSTRAP="${ROOT}/${TARGET}/bootstrap"
export SYSROOT="${ROOT}/${TARGET}/sysroot"

case $subcommand in
    build)
        [[ -n "${target}" ]] || die "build requires --target"
        depcheck
        prep
        download
        llvm_stage0
        sysroot_headers
        ;;
    clean)
        printf 'Cleaning natickOS toolchain\n'
        rm -rf "$BUILD" "$BOOTSTRAP" "$SYSROOT"
        ;;
esac