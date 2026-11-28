#!/bin/bash

# --------
# natickOS - Build Script
# --------
# ISC License
# Copyright (C) 2017-2026 Alexander Barris
# All Rights Reserved
set -eou pipefail

export EXEC="${0##*/}"

# Report an error and kill the build script
die() {
    echo "[FAIL] $*" >&2
    exit 1
}

# Basic Directory Structure
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" \
    || die "Cannot determine script directory"
export BUILDROOT="${SCRIPT_DIR}/build"

# ----- Helper Functions ----- #

# Show the build script usage.
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

# Export the cross-toolchain and target pkg-config settings.
build_env() {
    [[ -x "$TOOLCHAIN_DIR/bin/clang" ]] \
        || die "Toolchain missing: $TOOLCHAIN_DIR"

    [[ -f "$SYSROOT_DIR/usr/include/stdio.h" ]] \
        || die "musl headers missing: $SYSROOT_DIR"

    export PATH="$TOOLCHAIN_DIR/bin:$PATH"

    export CC="$TOOLCHAIN_DIR/bin/clang"
    export CXX="$TOOLCHAIN_DIR/bin/clang++"
    export AR="$TOOLCHAIN_DIR/bin/llvm-ar"
    export LD="$TOOLCHAIN_DIR/bin/ld.lld"
    export RANLIB="$TOOLCHAIN_DIR/bin/llvm-ranlib"
    export NM="$TOOLCHAIN_DIR/bin/llvm-nm"
    export STRIP="$TOOLCHAIN_DIR/bin/llvm-strip"
    export OBJCOPY="$TOOLCHAIN_DIR/bin/llvm-objcopy"
    export OBJDUMP="$TOOLCHAIN_DIR/bin/llvm-objdump"

    export HOSTCC=/usr/bin/clang
    export HOSTCXX=/usr/bin/clang++

    export PKG_CONFIG_SYSROOT_DIR="$SYSROOT_DIR"
    export PKG_CONFIG_LIBDIR="$SYSROOT_DIR/usr/lib/pkgconfig:$SYSROOT_DIR/usr/share/pkgconfig"
    export PKG_CONFIG_PATH=

    export CCACHE_DIR="$BUILDROOT/ccache"
    export CCACHE_MAXSIZE=20G
    export CCACHE_COMPILERCHECK=content
}

# Fetch a source archive into cache and verify its checksum.
fetch_source() {
    local url=$1
    local archive=$2
    local expected_sha256=$3
    local source_file=$archive

    if [[ ! -f "$archive" ]]; then
        mkdir -p -- "$(dirname -- "$archive")" \
            || die "Cannot create source download directory"
        source_file="${archive}.part"
        echo "[....] Downloading ${archive##*/}"
        curl -fL --retry 3 --progress-bar -o "$source_file" "$url" \
            || die "Download failed: $archive"
    fi

    echo "[....] Verifying ${source_file##*/}"
    printf '%s  %s\n' "$expected_sha256" "$source_file" |
        sha256sum --check --status \
        || die "Checksum mismatched: $source_file; remove it to download again"

    if [[ "$source_file" != "$archive" ]]; then
        mv -- "$source_file" "$archive" || die "Cannot finalize download: $archive"
    fi
}

# Fail early if a required host command is unavailable.
check_host_deps() {
    local tool

    for tool in "$@"; do
        command -v "$tool" >/dev/null 2>&1 \
            || die "Missing build-host tool: $tool"
    done
}

# ----- RPM Backend ----- #

# These helpers share the package-local context set by build_rpm_pkg.

# List the expected binary RPM paths for a spec.
rpm_output_paths() {
    local outputs filename

    outputs=$(rpmspec "${args[@]}" -q --rpms \
        --qf '%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm\n' "$spec") \
        || die "Cannot query RPM outputs: $spec"
    [[ -n "$outputs" ]] || die "No RPM outputs: $spec"
    while IFS= read -r filename; do
        printf '%s/RPMS/%s\n' "$top" "$filename"
    done <<< "$outputs"
}

# Read spec's BuildRequires, checking for host tools and saving target requirements.
read_rpm_build_requires() {
    local requirements requirement tool

    requirements=$(rpmspec "${args[@]}" -q --buildrequires "$spec") \
        || die "Cannot query BuildRequires: $spec"
    while IFS= read -r requirement; do
        [[ -n "$requirement" ]] || continue
        if [[ "$requirement" == natick-host-* ]]; then
            tool=${requirement#natick-host-}
            # TODO: Support versioned host commands
            [[ -n "$tool" && "$tool" != *[[:space:]]* ]] \
                || die "Expected an unversioned host command: $requirement"
            check_host_deps "$tool"
        else
            target_requires+=("$requirement")
        fi
    done <<< "$requirements"
}

# Resolve and download target dependencies with DNF w/o installing them.
# NOTE: This function needs 'sudo' because DNF4 (Dev Container base) needs
#       'sudo' in order to run 'dnf install'.
# TODO: Check if DNF5 has same requirement or if there's a way around this
download_rpm_build_deps() (
    local destination=$1 solver_root

    check_host_deps dnf sudo
    if [[ "$managed_repo" == 1 ]]; then
        refresh_build_repo
    fi
    [[ -f "$build_repo/repodata/repomd.xml" ]] \
        || die "No repository metadata in $build_repo; build or add the prerequisite RPMs first"
    solver_root=$(mktemp -d "$top/solver.XXXXXX")
    trap 'sudo rm -rf -- "$solver_root"' EXIT

    # Solve against an empty RPM database without installing or running scripts.
    sudo dnf --installroot="$solver_root" --forcearch="$target_arch" --releasever=0.0.1 \
        --repofrompath="natick-build,file://$build_repo" --repo=natick-build \
        --noplugins --nogpgcheck --setopt=install_weak_deps=False \
        --assumeyes --downloadonly --downloaddir="$destination" \
        install "${target_requires[@]}" || die "Cannot resolve target BuildRequires: $spec"
)

# Prepare the sysroot by overlaying dependency RPMs to a temporary directory
prepare_rpm_sysroot() {
    local rpmfile
    local -a packages=()

    if [[ -n "${NATICK_SYSROOT:-}" ]]; then
        SYSROOT_DIR=$(realpath -e -- "$NATICK_SYSROOT")
        echo "[NOTE] RPM sysroot (NATICK_SYSROOT override): $SYSROOT_DIR"
        return
    fi
    # musl bootstraps itself and Linux's Kbuild does not link against libc
    # musl-devel pulls the musl runtime libs in the same solve
    case "$name" in
        musl|linux) ;;
        *) target_requires+=(musl-devel) ;;
    esac
    if (( ${#target_requires[@]} == 0 )); then
        echo "[NOTE] RPM sysroot (bootstrap): $SYSROOT_DIR"
        return
    fi

    mkdir -p -- "$top"
    rpm_sysroot=$(mktemp -d "$top/sysroot.XXXXXX")

    mkdir -- "$rpm_sysroot/.rpms"
    download_rpm_build_deps "$rpm_sysroot/.rpms"
    shopt -s nullglob
    packages=("$rpm_sysroot/.rpms/"*.rpm)
    shopt -u nullglob
    (( ${#packages[@]} )) || die "DNF did not download any target BuildRequires: $spec"

    cp -a --reflink=auto -- "$SYSROOT_DIR/." "$rpm_sysroot/"

    # TODO: Have DNF4 install the RPMs? Or just continue to extract them?
    for rpmfile in "${packages[@]}"; do
        rpm2cpio "$rpmfile" | (
            cd -- "$rpm_sysroot"
            cpio -idmu --quiet --no-absolute-filenames
        ) || die "Cannot extract RPM dependency: $rpmfile"
    done
    rm -rf -- "$rpm_sysroot/.rpms"
    SYSROOT_DIR="$rpm_sysroot"
    echo "[NOTE] RPM sysroot (assembled from RPMs): $SYSROOT_DIR"
}

# Verify pkg-config requirements against the prepared target sysroot.
check_rpm_target_requires() {
    local requirement pattern='^pkgconfig\(([^)]+)\)(.*)$'

    for requirement in "${target_requires[@]}"; do
        if [[ "$requirement" =~ $pattern ]]; then
            pkg-config --print-errors --exists "${BASH_REMATCH[1]}${BASH_REMATCH[2]}" \
                || die "Missing target BuildRequires: $requirement (sysroot: $SYSROOT_DIR)"
        fi
    done
}

# Check for existing RPMs and whether any output needs target tools.
check_rpm_outputs() {
    local outputs rpmfile arch_dir

    outputs=$(rpm_output_paths)
    while IFS= read -r rpmfile; do
        arch_dir=${rpmfile%/*}
        if [[ "${arch_dir##*/}" != noarch ]]; then
            needs_target_tools=1
        fi
        if [[ -e "$rpmfile" || -L "$rpmfile" ]]; then
            (( overwrite == 1 )) || die "RPM already exists: $rpmfile; use --overwrite"
        fi
    done <<< "$outputs"
}

# Configure RPM cross-build phases without leaking target paths to dependency generators.
prepare_rpm_environment() {
    build_env
    export NATICK_TARGET="$TARGET" NATICK_TOOLCHAIN="$TOOLCHAIN_DIR" NATICK_SYSROOT="$SYSROOT_DIR"
    # Set target pkg-config paths in RPM phase scripts
    args+=(--define 'set_build_flags unset CFLAGS CPPFLAGS CXXFLAGS LT_SYS_LIBRARY_PATH; export LDFLAGS=-Wl,--build-id=sha1 PKG_CONFIG_PATH= PKG_CONFIG_SYSROOT_DIR="$NATICK_SYSROOT" PKG_CONFIG_LIBDIR="$NATICK_SYSROOT/usr/lib/pkgconfig:$NATICK_SYSROOT/usr/share/pkgconfig";' \
        --define '__brp_ldconfig %{nil}' \
        --define "__strip $STRIP" --define "__objdump $OBJDUMP")

    # Check target BuildRequires before clearing the environment for rpmbuild
    check_rpm_target_requires
    mkdir -p -- "$top"
    rpm_tools=$(mktemp -d "$top/cross-tools.XXXXXX")
    export NATICK_CROSS_TOOLS="$rpm_tools" NATICK_CROSS_HELPER="$SCRIPT_DIR/rpm/cross.sh"
    bash "$NATICK_CROSS_HELPER" tools
    unset PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_LIBDIR PKG_CONFIG_PATH
    build_args+=(--nodeps)
}

# Collect the spec's sources and patches in the RPM build tree
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

# Index the target's built binary RPMs w/o copying them.
refresh_build_repo() (
    local target_dir="$BUILDROOT/rpm/$TARGET" pkglist rpmfile

    mkdir -p -- "$build_repo"
    pkglist=$(mktemp "$build_repo/pkglist.XXXXXX")
    trap 'rm -f -- "$pkglist"' EXIT
    shopt -s nullglob
    for rpmfile in "$target_dir"/*/RPMS/{"$target_arch",noarch}/*.rpm; do
        printf '%s\n' "${rpmfile#"$target_dir/"}"
    done > "$pkglist"

    echo "[....] Refreshing local build repo: $build_repo"
    createrepo_c --baseurl="file://$target_dir/" --outputdir="$build_repo" \
        --pkglist="$pkglist" "$target_dir" || die "Cannot regenerate build repo metadata"
)

# Build binary and source RPMs, then refresh the managed repo (if enabled).
build_rpm_pkg() (
    local name=$1 overwrite=$2 target_arch=${TARGET%%-*}
    local needs_target_tools=0 rpm_sysroot='' rpm_tools='' build_repo='' managed_repo=0
    local -a args=() build_args=() target_requires=()

    local recipe_dir="$RECIPE_DIR/$name"
    local spec="$recipe_dir/$name.spec"
    local top="$BUILDROOT/rpm/$TARGET/$name"
    [[ -f "$spec" ]] || die "Spec missing: $spec"
    source "$SCRIPT_DIR/rpm/defines.sh"
    args=("${natick_rpm_defs[@]}" --target "$target_arch" --define "_topdir $top")
    # --target selects the Natick musl ABI, even on a host with the same CPU
    args+=(--define 'natick_cross 1' --define 'debug_package %{natick_cross_debug_package}')
    check_rpm_outputs
    if [[ -n "${NATICK_BUILD_REPO:-}" ]]; then
        build_repo=$(realpath -e -- "$NATICK_BUILD_REPO") || die "Cannot locate NATICK_BUILD_REPO"
    else
        check_host_deps createrepo_c
        build_repo="$BUILDROOT/rpm/$TARGET/repo"
        managed_repo=1
    fi
    local log_file="$top/build.log"
    mkdir -p -- "$top"
    echo "[NOTE] RPM build log: $log_file"
    (
        if (( needs_target_tools )); then
            trap 'rm -rf -- "$rpm_sysroot" "$rpm_tools"' EXIT
            PATH="$TOOLCHAIN_DIR/bin:$PATH" read_rpm_build_requires
            prepare_rpm_sysroot
            prepare_rpm_environment
        fi
        stage_rpm_sources
        build_status=0
        rpmbuild -ba "${args[@]}" "${build_args[@]}" "$spec" || build_status=$?
        if (( needs_target_tools )) && command -v ccache >/dev/null 2>&1; then
            echo "[NOTE] ccache statistics (shared cache)"
            ccache --show-stats || echo "[WARN] Cannot read ccache statistics" >&2
        fi
        (( build_status == 0 )) || die "RPM build failed: $name"
        if [[ "$managed_repo" == 1 ]]; then
            refresh_build_repo
        fi
    ) 2>&1 | tee "$log_file"
)

# Remove temporary build files (not including SRPMs and RPMs).
clean_rpm_pkg() {
    local top="$BUILDROOT/rpm/$TARGET/$1"

    echo "[....] Removing RPM build and staging files for $1"
    rm -rf -- "$top/BUILD" "$top/BUILDROOT" "$top/SOURCES" "$top"/sysroot.* "$top"/cross-tools.* \
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
    x86_64|aarch64) ;;
    *) die "Unsupported target: $target" ;;
esac
export TARGET="${target}-linux-musl"

export TOOLCHAIN_DIR="${BUILDROOT}/toolchain"
export SYSROOT_DIR="${BUILDROOT}/${TARGET}/sysroot"

export RECIPE_DIR="${SCRIPT_DIR}/pkg"
export SOURCES_DIR="${BUILDROOT}/src"

case "$subcommand" in
    build) build_rpm_pkg "$package" "$overwrite" ;;
    clean) clean_rpm_pkg "$package" ;;
esac