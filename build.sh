#!/bin/bash

# --------
# natickOS - Build Script
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

# ----- Helper Functions ----- #

usage() {
    echo "natickOS build script - vGIT"
    echo ""
    echo "Usage:"
    echo "  ${EXEC} (COMMAND) [option]"
    echo "COMMAND:"
    echo "  build ==> Build package"
    echo "  clean ==> Clean package"
    echo "  help  ==> Shows this message"
    echo ""
    echo "build option:"
    echo "  --target ARCH ==> (x86_64/aarch64)"
    echo "  --package PKG ==> Package name"
    echo "  --overwrite   ==> Overwrite existing package"
    echo ""
    echo "natickOS: <https://github.com/awlsomealex/natick>"
}

build_env() {
    [[ -x "$TOOLCHAIN_DIR/bin/clang" ]] \
        || die "Toolchain missing: $TOOLCHAIN_DIR"

    [[ -f "$SYSROOT_DIR/usr/include/stdio.h" ]] \
        || die "musl headers missing: $SYSROOT_DIR"

    export PATH="$TOOLCHAIN_DIR/bin:$PATH"

    export CC="$TOOLCHAIN_DIR/bin/clang"
    export CXX="$TOOLCHAIN_DIR/bin/clang++"
    export AR="$TOOLCHAIN_DIR/bin/llvm-ar"
    export RANLIB="$TOOLCHAIN_DIR/bin/llvm-ranlib"
    export NM="$TOOLCHAIN_DIR/bin/llvm-nm"
    export STRIP="$TOOLCHAIN_DIR/bin/llvm-strip"
    export OBJCOPY="$TOOLCHAIN_DIR/bin/llvm-objcopy"
    export OBJDUMP="$TOOLCHAIN_DIR/bin/llvm-objdump"
    export READELF="$TOOLCHAIN_DIR/bin/llvm-readelf"

    export HOSTCC=/usr/bin/clang
    export HOSTCXX=/usr/bin/clang++

    export PKG_CONFIG_SYSROOT_DIR="$SYSROOT_DIR"
    export PKG_CONFIG_LIBDIR="$SYSROOT_DIR/usr/lib/pkgconfig:$SYSROOT_DIR/usr/share/pkgconfig"
    export PKG_CONFIG_PATH=

    export CCACHE_DIR="$BUILDROOT/ccache"
    export CCACHE_MAXSIZE=20G
    export CCACHE_COMPILERCHECK=content
    #export CCACHE_LOGFILE="$CCACHE_DIR/ccache-debug.log"
}

fetch_source() {
    local url=$1
    local archive=$2
    local expected_sha256=$3

    mkdir -p -- "$(dirname -- "$archive")" \
        || die "Cannot create source download directory"

    if [[ -f "$archive" ]]; then
        echo "[....] Verifying cached source: ${archive##*/}"
        printf '%s  %s\n' "$expected_sha256" "$archive" |
            sha256sum --check --status \
            || die "Checksum mismatched: $archive; remove it to download again"
        return 0
    fi

    if [[ ! -f "$archive" ]]; then
        echo "[....] Downloading ${archive##*/}"
        curl -fL --retry 3 --progress-bar \
            -o "${archive}.part" "$url" \
            || die "Download failed: $archive"
    fi

    echo "[....] Verifying ${archive##*/}...."
    printf '%s  %s\n' "$expected_sha256" "${archive}.part" |
        sha256sum --check --status \
        || die "Checksum mismatched: ${archive}.part; remove it to download again"
     mv -- "${archive}.part" "$archive" \
        || die "Cannot finalize download: $archive"
}

check_host_deps() {
    local tool

    for tool in "$@"; do
        command -v "$tool" >/dev/null 2>&1 \
            || die "Missing build-host tool: $tool"
    done
}

# ----- RPM Backend ----- #

# These helpers share the package-local context set by build_rpm_pkg.
rpm_output_paths() {
    local spec_file=$1 output_top=$2 outputs filename

    outputs=$(rpmspec "${args[@]}" --define "_topdir $output_top" -q --rpms \
        --qf '%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm\n' "$spec_file") \
        || die "Cannot query RPM outputs: $spec_file"
    [[ -n "$outputs" ]] || die "No RPM outputs: $spec_file"
    while IFS= read -r filename; do
        printf '%s/RPMS/%s\n' "$output_top" "$filename"
    done <<< "$outputs"
}

# TODO: Drop rpm_sysroot_deps once the natickOS RPM repo can satisfy target
# BuildRequires.
prepare_rpm_sysroot() {
    local dep outputs rpmfile
    local -a packages=()

    if [[ -n "${NATICK_SYSROOT:-}" ]]; then
        SYSROOT_DIR=$(realpath -e -- "$NATICK_SYSROOT")
        echo "[....] RPM sysroot (NATICK_SYSROOT override): $SYSROOT_DIR"
        return
    fi
    if (( ${#rpm_sysroot_deps[@]} == 0 )); then
        echo "[....] RPM sysroot (baseline): $SYSROOT_DIR"
        return
    fi

    for dep in "${rpm_sysroot_deps[@]}"; do
        outputs=$(rpm_output_paths "$RECIPE_DIR/$dep/$dep.spec" "$BUILDROOT/rpm/$TARGET/$dep")
        while IFS= read -r rpmfile; do
            [[ -f "$rpmfile" ]] || die "Missing RPM: $rpmfile
Build it first: ./build.sh build --target $target_arch --package $dep"
            packages+=("$rpmfile")
        done <<< "$outputs"
    done

    mkdir -p -- "$top"
    rpm_sysroot=$(mktemp -d "$top/sysroot.XXXXXX")
    trap 'rm -rf -- "$rpm_sysroot"' EXIT
    cp -a --reflink=auto -- "$SYSROOT_DIR/." "$rpm_sysroot/"

    for rpmfile in "${packages[@]}"; do
        rpm2cpio "$rpmfile" | (
            cd -- "$rpm_sysroot"
            cpio -idmu --quiet --no-absolute-filenames
        ) || die "Cannot extract RPM dependency: $rpmfile"
    done
    SYSROOT_DIR="$rpm_sysroot"
    echo "[....] RPM sysroot (assembled from RPMs): $SYSROOT_DIR"
}

check_rpm_cross_requires() {
    local requirements requirement tool
    local pattern='^pkgconfig\(([^)]+)\)(.*)$'

    requirements=$(rpmspec "${args[@]}" -q --buildrequires "$spec") \
        || die "Cannot query BuildRequires: $spec"
    while IFS= read -r requirement; do
        if [[ "$requirement" == natick-host-* ]]; then
            tool=${requirement#natick-host-}
            [[ -n "$tool" && "$tool" != *[[:space:]]* ]] \
                || die "Expected an unversioned host command: $requirement"
            check_host_deps "$tool"
        elif [[ "$requirement" =~ $pattern ]]; then
            pkg-config --print-errors --exists "${BASH_REMATCH[1]}${BASH_REMATCH[2]}" \
                || die "Missing target BuildRequires: $requirement (sysroot: $SYSROOT_DIR)"
        fi
    done <<< "$requirements"
}

check_rpm_outputs() {
    local outputs rpmfile arch_dir host_arch

    host_arch=$(uname -m)
    outputs=$(rpm_output_paths "$spec" "$top")
    while IFS= read -r rpmfile; do
        arch_dir=${rpmfile%/*}
        if [[ "${arch_dir##*/}" != noarch && "$target_arch" != "$host_arch" && "$rpm_cross" != 1 ]]; then
            die "RPM build needs rpm_cross=1 in $recipe_dir/rpm.build"
        fi
        if [[ -e "$rpmfile" || -L "$rpmfile" ]]; then
            (( overwrite == 1 )) || die "RPM already exists: $rpmfile; use --overwrite"
        fi
    done <<< "$outputs"
}

prepare_rpm_environment() {
    build_env
    export NATICK_TARGET="$TARGET" NATICK_TOOLCHAIN="$TOOLCHAIN_DIR" NATICK_SYSROOT="$SYSROOT_DIR"
    # The target libraries come from the sysroot, not the host RPM database (yet).
    args+=(--define 'set_build_flags unset CFLAGS CPPFLAGS CXXFLAGS LT_SYS_LIBRARY_PATH; export LDFLAGS=-Wl,--build-id=sha1 PKG_CONFIG_PATH=;' \
        --define '__brp_ldconfig %{nil}' \
        --define "__strip $STRIP" --define "__objdump $OBJDUMP")

    check_rpm_cross_requires
    build_args+=(--nodeps)
}

stage_rpm_sources() {
    local metadata tag source source_name sha

    metadata=$(rpmspec "${args[@]}" -P "$spec" | awk '$1 ~ /^(Source|Patch)[0-9]*:$/ { print $1, $2 }') \
        || die "Cannot parse sources and patches: $spec"
    mkdir -p -- "$top/SOURCES"
    while read -r tag source; do
        [[ -n "$tag" ]] || continue
        source_name=${source##*/}
        [[ -n "$source_name" && "$source_name" != . && "$source_name" != .. ]] \
            || die "Invalid $tag filename: $source"
        if [[ "$source" == https://* || "$source" == http://* ]]; then
            sha=$(awk -v name="$source_name" '$2 == name { print $1 }' "$recipe_dir/sources")
            [[ "$sha" =~ ^[a-fA-F0-9]{64}$ ]] || die "Expected one SHA-256 for $source_name in $recipe_dir/sources"
            fetch_source "$source" "$SOURCES_DIR/$source_name" "$sha"
            cp -- "$SOURCES_DIR/$source_name" "$top/SOURCES/$source_name"
        elif [[ "$source" != "$source_name" ]]; then
            die "Local $tag must name a file alongside the spec: $source"
        else
            cp -- "$recipe_dir/$source_name" "$top/SOURCES/$source_name"
        fi
    done <<< "$metadata"
}

build_rpm_pkg() (
    local name=$1 overwrite=$2 target_arch=${TARGET%%-*}
    local rpm_cross=0 rpm_sysroot=''
    local -a args=() build_args=() rpm_sysroot_deps=()

    local recipe_dir="$RECIPE_DIR/$name"
    local spec="$recipe_dir/$name.spec"
    local top="$BUILDROOT/rpm/$TARGET/$name"
    [[ -f "$spec" ]] || die "Spec missing: $spec"
    if [[ -f "$recipe_dir/rpm.build" ]]; then
        source "$recipe_dir/rpm.build"
    fi

    source "$SCRIPT_DIR/rpm/defines.sh"
    args=(--target "$target_arch" "${natick_rpm_defs[@]}")
    check_rpm_outputs
    if [[ "$rpm_cross" == 1 ]]; then
        prepare_rpm_sysroot
    fi
    args+=(--define "_topdir $top")
    if [[ "$rpm_cross" == 1 ]]; then
        prepare_rpm_environment
    fi

    local log_file="$top/build.log"
    mkdir -p -- "$top"
    echo "[....] RPM build log: $log_file"
    {
        stage_rpm_sources
        rpmbuild -ba "${args[@]}" "${build_args[@]}" "$spec" || die "RPM build failed: $name"
    } 2>&1 | tee "$log_file"
)

clean_rpm_pkg() {
    local top="$BUILDROOT/rpm/$TARGET/$1"

    echo "[....] Removing RPM build and staging files for $1"
    rm -rf -- "$top/BUILD" "$top/BUILDROOT" "$top/SOURCES" "$top"/sysroot.* \
        || die "Cannot clean RPM build: $1"
}

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
package=''
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
        --package)
            if (($# < 2)) || [[ $2 == -* ]]; then
                die "--package requires a value"
            fi
            package=$2
            shift 2
            ;;
        --package=*)
            package=${1#*=}
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
if [[ ${package} == '' ]]; then
    die "No package specified."
fi
[[ "$package" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.+-]*$ ]] \
    || die "Invalid RPM package name: $package"

case "$target" in
    x86_64) export LINUX_ARCH="x86" ;;
    aarch64) export LINUX_ARCH="arm64" ;;
    *) die "Unsupported target: $target" ;;
esac
export TARGET="${target}-linux-musl"

export TOOLCHAIN_DIR="${BUILDROOT}/${TARGET}/toolchain"
export SYSROOT_DIR="${BUILDROOT}/${TARGET}/sysroot"

export RECIPE_DIR="${SCRIPT_DIR}/pkg"
export SOURCES_DIR="${BUILDROOT}/src"

case "$subcommand" in
    build) build_rpm_pkg "$package" "$overwrite" ;;
    clean) clean_rpm_pkg "$package" ;;
esac