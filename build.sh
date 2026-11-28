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

# Fetch a source archive into cache and verify its checksum.
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
    local spec_file=$1 output_top=$2 outputs filename

    outputs=$(rpmspec "${args[@]}" --define "_topdir $output_top" -q --rpms \
        --qf '%{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm\n' "$spec_file") \
        || die "Cannot query RPM outputs: $spec_file"
    [[ -n "$outputs" ]] || die "No RPM outputs: $spec_file"
    while IFS= read -r filename; do
        printf '%s/RPMS/%s\n' "$output_top" "$filename"
    done <<< "$outputs"
}

# Read spec's BuildRequires, checking for host tools and saving target requirements.
read_rpm_build_requires() {
    local requirements requirement tool

    requirements=$(rpmspec "${args[@]}" --define "_topdir $top" -q --buildrequires "$spec") \
        || die "Cannot query BuildRequires: $spec"
    while IFS= read -r requirement; do
        [[ -n "$requirement" ]] || continue
        if [[ "$requirement" == natick-host-* ]]; then
            tool=${requirement#natick-host-}
            [[ -n "$tool" && "$tool" != *[[:space:]]* ]] \
                || die "Expected an unversioned host command: $requirement"
            check_host_deps "$tool"
        else
            target_requires+=("$requirement")
        fi
    done <<< "$requirements"
}

# Resolve and download target dependencies with DNF w/o installing them.
download_rpm_build_deps() (
    local destination=$1 solver_root

    (( ${#target_requires[@]} )) || return 0

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

# Select a sysroot, overlaying dependency RPMs on a temporary copy if needed.
prepare_rpm_sysroot() {
    local dep outputs rpmfile
    local -a packages=()

    if [[ -n "${NATICK_SYSROOT:-}" ]]; then
        SYSROOT_DIR=$(realpath -e -- "$NATICK_SYSROOT")
        echo "[....] RPM sysroot (NATICK_SYSROOT override): $SYSROOT_DIR"
        return
    fi
    if [[ -z "$build_repo" ]] && (( ${#rpm_sysroot_deps[@]} == 0 )); then
        echo "[....] RPM sysroot (baseline): $SYSROOT_DIR"
        return
    fi

    mkdir -p -- "$top"
    rpm_sysroot=$(mktemp -d "$top/sysroot.XXXXXX")
    trap 'rm -rf -- "$rpm_sysroot"' EXIT

    if [[ -n "$build_repo" ]]; then
        mkdir -- "$rpm_sysroot/.rpms"
        download_rpm_build_deps "$rpm_sysroot/.rpms"
        shopt -s nullglob
        packages=("$rpm_sysroot/.rpms/"*.rpm)
        shopt -u nullglob
    else
        for dep in "${rpm_sysroot_deps[@]}"; do
            outputs=$(rpm_output_paths "$RECIPE_DIR/$dep/$dep.spec" "$BUILDROOT/rpm/$TARGET/$dep")
            while IFS= read -r rpmfile; do
                [[ -f "$rpmfile" ]] || die "Missing RPM: $rpmfile. Build it first: ./build.sh build --target $target_arch --package $dep"
                packages+=("$rpmfile")
            done <<< "$outputs"
        done
    fi

    cp -a --reflink=auto -- "$SYSROOT_DIR/." "$rpm_sysroot/"

    for rpmfile in "${packages[@]}"; do
        rpm2cpio "$rpmfile" | (
            cd -- "$rpm_sysroot"
            cpio -idmu --quiet --no-absolute-filenames
        ) || die "Cannot extract RPM dependency: $rpmfile"
    done
    if [[ -n "$build_repo" ]]; then
        rm -rf -- "$rpm_sysroot/.rpms"
    fi
    SYSROOT_DIR="$rpm_sysroot"
    echo "[....] RPM sysroot (assembled from RPMs): $SYSROOT_DIR"
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

# Check cross-build eligibility and guard against accidental RPM overwrites.
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

# Configure RPM cross-build phases without leaking target paths to dependency generators.
prepare_rpm_environment() {
    build_env
    export NATICK_TARGET="$TARGET" NATICK_TOOLCHAIN="$TOOLCHAIN_DIR" NATICK_SYSROOT="$SYSROOT_DIR"
    # Set target pkg-config paths in RPM phase scripts
    args+=(--define 'set_build_flags unset CFLAGS CPPFLAGS CXXFLAGS LT_SYS_LIBRARY_PATH; export LDFLAGS=-Wl,--build-id=sha1 PKG_CONFIG_PATH= PKG_CONFIG_SYSROOT_DIR="$NATICK_SYSROOT" PKG_CONFIG_LIBDIR="$NATICK_SYSROOT/usr/lib/pkgconfig:$NATICK_SYSROOT/usr/share/pkgconfig";' \
        --define '__brp_ldconfig %{nil}' \
        --define "__strip $STRIP" --define "__objdump $OBJDUMP")

    # Check target BuildRequires before clearing the environment for rpmbuild.
    check_rpm_target_requires
    unset PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_LIBDIR PKG_CONFIG_PATH
    build_args+=(--nodeps)
}

# Collect the spec's sources and patches in the RPM build tree.
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
    local rpm_cross=0 rpm_sysroot='' build_repo='' managed_repo=0
    local -a args=() build_args=() rpm_sysroot_deps=() target_requires=()

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
    if [[ -n "${NATICK_BUILD_REPO:-}" ]]; then
        build_repo=$(realpath -e -- "$NATICK_BUILD_REPO") || die "Cannot locate NATICK_BUILD_REPO"
    elif [[ "${NATICK_USE_DNF:-0}" == 1 ]]; then
        check_host_deps createrepo_c
        build_repo="$BUILDROOT/rpm/$TARGET/repo"
        managed_repo=1
    fi
    if [[ "$rpm_cross" == 1 ]]; then
        PATH="$TOOLCHAIN_DIR/bin:$PATH" read_rpm_build_requires
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
        if [[ "$managed_repo" == 1 ]]; then
            refresh_build_repo
        fi
    } 2>&1 | tee "$log_file"
)

# Remove temporary build files (not including SRPMs and RPMs).
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

export TOOLCHAIN_DIR="${BUILDROOT}/toolchain"
export SYSROOT_DIR="${BUILDROOT}/${TARGET}/sysroot"

export RECIPE_DIR="${SCRIPT_DIR}/pkg"
export SOURCES_DIR="${BUILDROOT}/src"

case "$subcommand" in
    build) build_rpm_pkg "$package" "$overwrite" ;;
    clean) clean_rpm_pkg "$package" ;;
esac