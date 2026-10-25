#!/bin/bash

# --------
# natickOS - Toolchain Script
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
export ROOT="${SCRIPT_DIR}/build"
export VALIDATE="${SCRIPT_DIR}/validate"
export SOURCES="${ROOT}/src"

# Toolchain Versions
source "$SCRIPT_DIR/toolchain.sources" \
    || die "Cannot load toolchain.sources"

# Ccache
export CCACHE_DIR="${ROOT}/ccache"
export CCACHE_SLOPPINESS=pch_defines,time_macros
export CCACHE_MAXSIZE=20G
export CCACHE_COMPILERCHECK=content
#export CCACHE_LOGFILE="$CCACHE_DIR/ccache-debug.log"

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
    ccache_ver=$(ccache --print-version) || die "Missing Ccache (youre gonna want this)!"
    git_ver=$(git --version) || die "Missing git version control system!"
    git_ver=${git_ver#git version }
    curl_ver=$(curl --version | awk 'NR == 1 { print $2 }') || die "Missing curl!"
    xz_ver=$(xz --version | awk 'NR == 1 { print $NF }') || die "Missing xz!"
    python_ver=$(python3 --version | awk '{ print $2 }') || die "Missing Python 3!"
    pkgconf_ver=$(pkg-config --version) || die "Missing pkg-config!"
    echo "----"
    echo "    Clang ${clang_ver} (LLVM ${llvm_ver}, LLD ${lld_ver})"
    echo "        with CMake ${cmake_ver} / Ninja ${ninja_ver} / Ccache ${ccache_ver}"
    echo "    Git ${git_ver}, cURL ${curl_ver}, XZ ${xz_ver}, Python ${python_ver}"
    echo "    pkg-config ${pkgconf_ver}"
    echo "----"
    echo "[DONE] All dependencies met."
}

fetch_source() {
    local url=$1
    local archive=$2
    local dir=$3
    local expected_sha256=$4

    if [[ ! -f "$archive" ]]; then
        echo "[....] Downloading $archive"
        curl -fL --retry 3 --progress-bar \
            -o "${archive}.part" "$url" \
            || die "Download failed: $archive"

        echo "[....] Verifying $archive"
        printf '%s  %s\n' "$expected_sha256" "${archive}.part" |
            sha256sum --check --status \
            || die "Checksum mismatch: ${archive}.part"

        mv "${archive}.part" "$archive" \
            || die "Cannot finalize download: ${archive}.part"
    else
        echo "[....] Verifying cached source: $archive"
        printf '%s  %s\n' "$expected_sha256" "$archive" |
            sha256sum --check --status \
            || die "Checksum mismatch: $archive; remove it to download again"
    fi

    [[ -d "$dir" ]] && return 0

    echo "[....] Extracting $archive"
    tar -xf "$archive" || die "Extraction failed: ${archive}"
}

# ---- Core Functions ---- #

prep() {
    if [[ -d "$BUILD" ||  -d "$TOOLCHAIN" ||  -d "$SYSROOT" ]]; then
        ((overwrite == 0)) && die "Existing toolchain found. Exiting...."
        echo "[....] Cleaning existing toolchain...."
        rm -rf "$BUILD" "$TOOLCHAIN" "$SYSROOT"
    fi
    mkdir -p "$SOURCES" "$BUILD" "$TOOLCHAIN" "$SYSROOT"
    echo "[DONE] Directories ready."
}

download() {
    local actual_commit

    cd "$SOURCES"

    if [[ ! -d llvm-project ]]; then
        git clone \
            --progress \
            --depth 1 \
            --branch "llvmorg-${LLVM_VER}" \
            https://github.com/llvm/llvm-project.git \
            || die "LLVM clone failed"
    fi

    actual_commit=$(git -C llvm-project rev-parse --verify 'HEAD^{commit}') \
        || die "Cannot determine LLVM checkout commit"

    [[ "$actual_commit" == "$LLVM_COMMIT" ]] \
        || die "LLVM commit mismatch: expected $LLVM_COMMIT, got $actual_commit"

    fetch_source \
        "https://cdn.kernel.org/pub/linux/kernel/v${LINUX_VER%%.*}.x/linux-${LINUX_VER}.tar.xz" \
        "linux-${LINUX_VER}.tar.xz" \
        "linux-${LINUX_VER}" \
        "$LINUX_SHA256"
    
    fetch_source \
        "https://musl.libc.org/releases/musl-${MUSL_VER}.tar.gz" \
        "musl-${MUSL_VER}.tar.gz" \
        "musl-${MUSL_VER}" \
        "$MUSL_SHA256"
}

llvm_build() {
    local build_dir="$BUILD/llvm"

    echo "[....] Configuring bootstrap Clang/LLVM...."
    cmake -S "$SOURCES/llvm-project/llvm" \
          -B "$build_dir" \
          -G Ninja \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_C_COMPILER=/usr/bin/clang \
          -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
          -DCMAKE_C_COMPILER_LAUNCHER=ccache \
          -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
          -DCMAKE_INSTALL_PREFIX="$TOOLCHAIN" \
          -DCMAKE_INSTALL_LIBDIR=lib \
          -DDEFAULT_SYSROOT="$SYSROOT" \
          -DLLVM_ENABLE_PROJECTS="clang;lld" \
          -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET" \
          -DLLVM_TARGETS_TO_BUILD="Native;$llvm_target" \
          -DLLVM_USE_LINKER=lld \
          -DLLVM_ENABLE_ASSERTIONS=OFF \
          -DLLVM_INCLUDE_TESTS=OFF \
          -DLLVM_INCLUDE_EXAMPLES=OFF \
          -DLLVM_INCLUDE_BENCHMARKS=OFF \
          -DLLVM_ENABLE_LIBCXX=OFF \
          -DLLVM_ENABLE_LIBEDIT=OFF \
          -DLLVM_ENABLE_LIBXML2=OFF \
          -DLLVM_ENABLE_ZLIB=OFF \
          -DLLVM_ENABLE_ZSTD=OFF \
          -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
          -DCLANG_DEFAULT_RTLIB=compiler-rt \
          -DCLANG_DEFAULT_UNWINDLIB=libunwind \
          -DCLANG_DEFAULT_LINKER=lld \
          || die "Clang/LLVM configuration failed"

    echo "[....] Building Clang/LLVM...."
    cmake --build "$build_dir" --parallel \
        || die "Clang/LLVM build failed"

    cmake --install "$build_dir" \
        || die "Clang/LLVM installation failed"
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
        CC="$TOOLCHAIN/bin/clang --target=$TARGET --sysroot=$SYSROOT --ld-path=$TOOLCHAIN/bin/ld.lld" \
        || die "musl configuration failed"

    echo "[....] Exporting musl headers...." 
    make DESTDIR="$SYSROOT" install-headers \
        || die "musl header installation failed"
)

compiler_rt_builtins() {
    local resource_dir

    local build_dir="$BUILD/compiler-rt-builtins"

    resource_dir=$("$TOOLCHAIN/bin/clang" -print-resource-dir) \
        || die "Cannot locate Clang resource directory"

    echo "[....] Configuring compiler-rt builtins...."
    cmake -S "$SOURCES/llvm-project/compiler-rt/lib/builtins" \
        -B "$build_dir" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR="$triple_target" \
        -DCMAKE_C_COMPILER="$TOOLCHAIN/bin/clang" \
        -DCMAKE_CXX_COMPILER="$TOOLCHAIN/bin/clang++" \
        -DCMAKE_ASM_COMPILER="$TOOLCHAIN/bin/clang" \
        -DCMAKE_C_COMPILER_TARGET="$TARGET" \
        -DCMAKE_CXX_COMPILER_TARGET="$TARGET" \
        -DCMAKE_ASM_COMPILER_TARGET="$TARGET" \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_AR="$TOOLCHAIN/bin/llvm-ar" \
        -DCMAKE_RANLIB="$TOOLCHAIN/bin/llvm-ranlib" \
        -DCMAKE_SYSROOT="$SYSROOT" \
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
        -DCMAKE_INSTALL_PREFIX="$resource_dir" \
        -DLLVM_CMAKE_DIR="$TOOLCHAIN/lib/cmake/llvm" \
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
        -DCOMPILER_RT_INCLUDE_TESTS=OFF \
        || die "Builtins configuration failed"

    echo "[....] Building compiler-rt builtins...."
    cmake --build "$build_dir" --parallel \
        || die "Builtins build failed"

    cmake --install "$build_dir" \
        || die "Builtins installation failed"

}

validate_builtins() {
    local archive
    local resource_dir

    local check_dir="$BUILD/validate"

    archive=$("$TOOLCHAIN/bin/clang" \
        --target="$TARGET" \
        --sysroot="$SYSROOT" \
        --rtlib=compiler-rt \
        --print-libgcc-file-name) \
        || die "Cannot locate builtins"

    resource_dir=$("$TOOLCHAIN/bin/clang" -print-resource-dir) \
        || die "Cannot locate Clang resource directory"

    [[ -s "$archive" ]] || die "Builtins missing: $archive"

    mkdir -p "$check_dir"

    # Restricts header searches to Clang's headers and musl sysroot
    "$TOOLCHAIN/bin/clang" \
        --target="$TARGET" \
        --sysroot="$SYSROOT" \
        -nostdinc \
        -isystem "$resource_dir/include" \
        -isystem "$SYSROOT/usr/include" \
        -O0 -ffreestanding -fno-stack-protector \
        -c "$SCRIPT_DIR/validate/check.c" -o "$check_dir/check.o" \
        || die "Target compilation or header check failed"

    # Confirm test actually requires runtime helper
    "$TOOLCHAIN/bin/llvm-nm" --undefined-only "$check_dir/check.o" \
        > "$check_dir/undefined-before.txt"
    
    grep -w '__udivti3' "$check_dir/undefined-before.txt" \
        || die "Test did not generate the expected builtin call"

    # Resolve it without requiring libc/executing startup files
    "$TOOLCHAIN/bin/ld.lld" -r \
        "$check_dir/check.o" "$archive" \
        -o "$check_dir/linked.o" \
        || die "Builtins relocatable link failed"
    
    "$TOOLCHAIN/bin/llvm-nm" --defined-only "$check_dir/linked.o" \
        > "$check_dir/defined-after.txt"

    grep -E ' [Tt] __udivti3$' "$check_dir/defined-after.txt" \
        || die "Builtin was not resolved from the archive"

    "$TOOLCHAIN/bin/llvm-readelf" -h "$check_dir/linked.o"

    echo "[DONE] Bootstrap smoke test passed."
}

musl_libc() (
    local archive
    archive=$("$TOOLCHAIN/bin/clang" \
        --target="$TARGET" \
        --sysroot="$SYSROOT" \
        --rtlib=compiler-rt \
        --print-libgcc-file-name) \
        || die "Cannot locate builtins"
    [[ -s "$archive" ]] || die "Builtins missing: $archive"

    cd "$BUILD/musl"

    echo "[....] Configuring musl libc...."
    "$SOURCES/musl-${MUSL_VER}/configure" \
        --target="$TARGET" \
        --prefix=/usr \
        --libdir=/usr/lib \
        --syslibdir=/lib \
        --disable-gcc-wrapper \
        CC="ccache $TOOLCHAIN/bin/clang --target=$TARGET --sysroot=$SYSROOT --ld-path=$TOOLCHAIN/bin/ld.lld" \
        AR="$TOOLCHAIN/bin/llvm-ar" \
        RANLIB="$TOOLCHAIN/bin/llvm-ranlib" \
        LIBCC="$archive" \
        || die "musl libc configuration failed"

    echo "[....] Building musl libc...."
    make -j"$(nproc)" \
        || die "musl libc build failed"

    make DESTDIR="$SYSROOT" install \
        || die "musl libc installation failed"
)

validate_libc() {
    local check_dir="$BUILD/validate"
    local CC=(
        "$TOOLCHAIN/bin/clang"
        "--target=$TARGET"
        "--sysroot=$SYSROOT"
        "--ld-path=$TOOLCHAIN/bin/ld.lld"
        --rtlib=compiler-rt
        --unwindlib=none
    )

    mkdir -p "$check_dir"

    "${CC[@]}" -v -static "$VALIDATE/hello.c" -o "$check_dir/hello-static" \
        || die "hello-static compilation failed"

    if ((SAME_ARCH == 0)); then
        echo "[SKIP] hello-static execution: host arch differs."
    else
        "$check_dir/hello-static" \
            || die "hello-static execution failed"
    fi

    "${CC[@]}" -v "$VALIDATE/hello.c" -o "$check_dir/hello-dynamic" \
        || die "hello-dynamic compilation failed"
    "$TOOLCHAIN/bin/llvm-readelf" \
        --program-headers --dynamic "$check_dir/hello-dynamic"

    if ((SAME_ARCH == 0)); then
        echo "[SKIP] hello-dynamic execution: host arch differs."
    else
        "$SYSROOT/usr/lib/libc.so" \
            --library-path "$SYSROOT/usr/lib" \
            "$check_dir/hello-dynamic" \
            || die "hello-dynamic execution failed"
    fi
}

llvm_runtimes() {
    local build_dir="$BUILD/llvm-runtimes"
    local link_flags="--rtlib=compiler-rt --unwindlib=none --ld-path=$TOOLCHAIN/bin/ld.lld"

    echo "[....] Configuring LLVM C++ runtimes...."
    cmake -S "$SOURCES/llvm-project/runtimes" \
        -B "$build_dir" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR="$triple_target" \
        -DCMAKE_C_COMPILER="$TOOLCHAIN/bin/clang" \
        -DCMAKE_CXX_COMPILER="$TOOLCHAIN/bin/clang++" \
        -DCMAKE_ASM_COMPILER="$TOOLCHAIN/bin/clang" \
        -DCMAKE_C_COMPILER_TARGET="$TARGET" \
        -DCMAKE_CXX_COMPILER_TARGET="$TARGET" \
        -DCMAKE_ASM_COMPILER_TARGET="$TARGET" \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_AR="$TOOLCHAIN/bin/llvm-ar" \
        -DCMAKE_RANLIB="$TOOLCHAIN/bin/llvm-ranlib" \
        -DCMAKE_SYSROOT="$SYSROOT" \
        -DCMAKE_CXX_FLAGS="-nostdlib++" \
        -DCMAKE_EXE_LINKER_FLAGS="$link_flags" \
        -DCMAKE_SHARED_LINKER_FLAGS="$link_flags" \
        -DCMAKE_MODULE_LINKER_FLAGS="$link_flags" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx" \
        -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET" \
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
        -DLIBCXX_HAS_MUSL_LIBC=ON \
        -DLIBCXX_CXX_ABI=libcxxabi \
        -DLIBCXX_USE_COMPILER_RT=ON \
        -DLIBCXXABI_USE_COMPILER_RT=ON \
        -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
        -DLIBUNWIND_USE_COMPILER_RT=ON \
        -DLIBCXX_ENABLE_SHARED=ON \
        -DLIBCXX_ENABLE_STATIC=ON \
        -DLIBCXX_STATICALLY_LINK_ABI_IN_STATIC_LIBRARY=ON \
        -DLIBCXXABI_ENABLE_SHARED=ON \
        -DLIBCXXABI_ENABLE_STATIC=ON \
        -DLIBUNWIND_ENABLE_SHARED=ON \
        -DLIBUNWIND_ENABLE_STATIC=ON \
        -DLIBCXX_INCLUDE_TESTS=OFF \
        -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
        -DLIBCXXABI_INCLUDE_TESTS=OFF \
        -DLIBUNWIND_INCLUDE_TESTS=OFF \
        || die "LLVM runtimes configuration failed"

        echo "[....] Building LLVM C++ runtimes...."
        cmake --build "$build_dir" --parallel \
            || die "LLVM runtimes build failed"

        DESTDIR="$SYSROOT" cmake --install "$build_dir" \
            || die "LLVM runtimes installation failed"
}

validate_runtimes() {
    local check_dir="$BUILD/validate"
    local -a cxx=(
        "$TOOLCHAIN/bin/clang++"
        "--target=$TARGET"
        "--sysroot=$SYSROOT"
        "--ld-path=$TOOLCHAIN/bin/ld.lld"
        --rtlib=compiler-rt
        --unwindlib=libunwind
        -std=c++17
        -O0
        -pthread
        -nostdinc++
        -isystem "$SYSROOT/usr/include/c++/v1"
        -nostdlib++
        "-L$SYSROOT/usr/lib"
    )

    mkdir -p "$check_dir"

    echo "[....] Testing static C++ runtimes...."
    "${cxx[@]}" -v -static "$VALIDATE/hello.cpp" \
        -Wl,--start-group -lc++ -lc++abi -lunwind -Wl,--end-group \
        -o "$check_dir/cxx-static" \
        || die "Static C++ compilation failed"

    if ((SAME_ARCH == 0)); then
        echo "[SKIP] cxx-static execution: host arch differs."
    else
        "$check_dir/cxx-static" \
        || die "Static C++ execution failed"
    fi

    echo "[....] Testing dynamic C++ runtimes...."
    "${cxx[@]}" -v "$VALIDATE/hello.cpp" \
        -lc++ -lc++abi -lunwind \
        -o "$check_dir/cxx-dynamic" \
        || die "Dynamic C++ compilation failed"

    "$TOOLCHAIN/bin/llvm-readelf" \
        --program-headers --dynamic "$check_dir/cxx-dynamic" \
        || die "Dynamic C++ ELF inspection failed"

    if ((SAME_ARCH == 0)); then
        echo "[SKIP] cxx-dynamic execution: host arch differs."
    else
        "$SYSROOT/usr/lib/libc.so" \
            --library-path "$SYSROOT/usr/lib" \
            "$check_dir/cxx-dynamic" \
            || die "Dynamic C++ execution failed"
    fi
}

validate_toolchain() (
    export LC_ALL=C

    local check_dir="$BUILD/validate-toolchain"
    local tool
    local mode
    local program
    local target
    local -a flags 

    mkdir -p "$check_dir"

    for tool in clang clang++ ld.lld llvm-ar llvm-ranlib \
                llvm-nm llvm-strip llvm-objcopy llvm-readelf; do
        echo "[....] Checking host tool: $tool"

        "$TOOLCHAIN/bin/$tool" --version \
            > "$check_dir/$tool.version.txt" 2>&1 \
            || die "Tool execution failed: $tool"
    done

    target=$("$TOOLCHAIN/bin/clang" -dumpmachine) \
        || die "Cannot determine compiler default target"

    case "$target" in
        "$TARGET"|"$triple_target"-*-linux-musl) ;;
        *) die "Unexpected compiler default target: $target" ;;
    esac

    for mode in static dynamic; do
        flags=()
        if [[ "$mode" == static ]]; then
            flags=(-static)
        fi
        
        echo "[....] Building $mode target C/C++ tests...."

        "$TOOLCHAIN/bin/clang" -v "${flags[@]}" \
            "$VALIDATE/hello.c" \
            -o "$check_dir/c-$mode" \
            || die "Final compiler C $mode build failed"

        "$TOOLCHAIN/bin/clang++" -v "${flags[@]}" \
            -std=c++17 -pthread "$VALIDATE/hello.cpp" \
            -o "$check_dir/cxx-$mode" \
            || die "Final compiler C++ $mode build failed"

        for program in "c-$mode" "cxx-$mode"; do
            "$TOOLCHAIN/bin/llvm-readelf" \
                --file-header --program-headers --dynamic \
                "$check_dir/$program" \
                > "$check_dir/$program.elf.txt" \
                || die "ELF inspection failed: $program"

            grep -F "Machine:" "$check_dir/$program.elf.txt" |
                grep -F "$machine" >/dev/null \
                || die "Wrong target architecture: $program"

            if [[ "$mode" == dynamic ]]; then
                grep -F \
                    "[Requesting program interpreter: $interpreter]" \
                    "$check_dir/$program.elf.txt" >/dev/null \
                    || die "Wrong target interpreter: $program"
            elif grep -q 'INTERP' "$check_dir/$program.elf.txt"; then
                die "Static test unexpectedly needs an interpreter: $program"
            fi

            if ((SAME_ARCH == 0)); then
                echo "[SKIP] $program execution: host arch differs."
                continue
            fi

            if [[ "$mode" == static ]]; then
                "$check_dir/$program" \
                    || die "Target execution failed: $program"
            else
                "$SYSROOT/usr/lib/libc.so" \
                    --library-path "$SYSROOT/usr/lib" \
                    "$check_dir/$program" \
                    || die "Target execution failed: $program"
            fi
        done
    done
    
    echo "[DONE] Final compiler runs and builds target C/C++ programs."
    echo "[INFO] Validation reports: $check_dir"
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

case $target in
    x86_64)
        triple_target="x86_64"
        llvm_target="X86"
        linux_target="x86"
        interpreter=/lib/ld-musl-x86_64.so.1
        machine="Advanced Micro Devices X86-64"
        ;;
    aarch64)
        triple_target="aarch64"
        llvm_target="AArch64"
        linux_target="arm64"
        interpreter=/lib/ld-musl-aarch64.so.1
        machine="AArch64"
        ;;
    *) die "Unsupported target: $target" ;;
esac

export SAME_ARCH=0
if [[ "$(uname -m)" == "$triple_target" ]]; then
    SAME_ARCH=1
fi

export TARGET="${triple_target}-linux-musl"
export BUILD="${ROOT}/${TARGET}/work"
export SYSROOT="${ROOT}/${TARGET}/sysroot"
export TOOLCHAIN="${ROOT}/${TARGET}/toolchain"

case $subcommand in
    build)
        [[ -n "${target}" ]] || die "build requires --target"
        depcheck
        prep
        download
        ccache --zero-stats
        llvm_build
        sysroot_headers
        compiler_rt_builtins
        validate_builtins
        musl_libc
        validate_libc
        llvm_runtimes
        validate_runtimes
        validate_toolchain
        ccache --show-stats
        ;;
    clean)
        printf 'Cleaning natickOS toolchain\n'
        rm -rf "$BUILD" "$TOOLCHAIN" "$SYSROOT"
        ;;
esac