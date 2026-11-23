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
export OUTPUT_DIR="${SCRIPT_DIR}/out"

# Dependency Resolution
declare -A dependency_state=()
declare -a build_order=()

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
    echo "  --format FMT  ==> Build format (btr|rpm, default: btr)"
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

extract_source() (
    local archive=$1
    local destination=$2

    local temporary

    [[ ! -e "$destination" ]] \
        || die "Source directory already exists: $destination"
    
    mkdir -p -- "$(dirname -- "$destination")" \
        || die "Cannot create package work directory"

    temporary=$(mktemp -d "${destination}.tmp.XXXXXX") \
        || die "Cannot create temporary extraction directory"

    trap 'rm -rf -- "$temporary"' EXIT

    echo "[....] Extracting $archive"
    tar -xf "$archive" \
        -C "$temporary" \
        --strip-components=1 \
        || die "Extraction failed: ${archive}"

    mv -T -- "$temporary" "$destination" \
        || die "Cannot finalize source directory: $destination"
)

apply_patches() {
    local patch_dir=$1
    shift

    local patch_file
    for patch_file in "$@"; do
        [[ -f "$patch_dir/$patch_file" ]] \
            || die "Patch missing: $patch_dir/$patch_file"

        echo "[....] Applying $patch_file...."

        patch --batch --forward --fuzz=0 -p1 \
            < "$patch_dir/$patch_file" \
            || die "Patch failed: $patch_file"
    done
}

package_output() (
    local staging_dir=$1
    local package_file=$2

    local temporary

    [[ -d "$staging_dir" ]] \
        || die "Staging directory missing: $staging_dir"

    mkdir -p -- "$(dirname -- "$package_file")" \
        || die "Cannot create package output directory"

    temporary=$(mktemp "${package_file}.tmp.XXXXXX") \
        || die "Cannot create temporary package"

    trap 'rm -f -- "$temporary"' EXIT

    echo "[....] Packaging ${package_file##*/}"

    tar \
        --sort=name \
        --owner=0 \
        --group=0 \
        --numeric-owner \
        -I 'zstd -T0 -6' \
        -cf "$temporary" \
        -C "$staging_dir" \
        . \
        || die "Package creation failed"

    chmod 644 "$temporary" \
        || die "Cannot set package permissions"

    mv -f -- "$temporary" "$package_file" \
        || die "Cannot finalize package: $package_file"
)

# ----- Dependency Handling ----- #

check_host_deps() {
    local tool

    for tool in "$@"; do
        command -v "$tool" >/dev/null 2>&1 \
            || die "Missing build-host tool: $tool"
    done
}

read_build_deps() (
    local requested=$1

    local dependency
    local -a bld_deps=()

    local recipe="$RECIPE_DIR/$requested/$requested.btr"
    [[ -f "$recipe" ]] \
        || die "Recipe missing: $requested"
    
    source "$recipe" >&2 \
        || die "Cannot read recipe: $requested"

    for dependency in "${bld_deps[@]}"; do
        printf '%s\n' "$dependency"
    done 
)

resolve_package() {
    local requested=$1
    local chain=${2-}

    local dependencies
    local dependency

    case "${dependency_state[$requested]-}" in
        visiting)
            die "Dependency cycle: ${chain}${requested}"
            ;;
        complete)
            return 0
            ;;
    esac

    dependency_state["$requested"]=visiting

    dependencies=$(read_build_deps "$requested") \
        || die "Cannot resolve dependencies for $requested"

    while IFS= read -r dependency; do
        [[ -n "$dependency" ]] || continue

        resolve_package \
            "$dependency" \
            "${chain}${requested} -> "
    done <<< "$dependencies"

    dependency_state["$requested"]=complete
    build_order+=("$requested")
}

resolve_build_order() {
    dependency_state=()
    build_order=()

    resolve_package "$1"
}

package_archive_path() (
    local requested=$1

    local name='' version='' release=''
    local -a bld_deps=()

    local recipe="$RECIPE_DIR/$requested/$requested.btr"
    [[ -f "$recipe" ]] \
        || die "Recipe missing: $recipe"

    source "$recipe" >&2 \
        || die "Cannot read recipe: $recipe"

    printf '%s/%s-%s-%s.%s.tar.zst\n' \
        "$PKG_DIR" "$name" "$version" "$release" "$TARGET"
)

prepare_dependency_sysroot() (
    local requested=$1
    local destination=$2
    local baseline=$SYSROOT_DIR

    local temporary
    local dependency archive

    resolve_build_order "$requested"

    [[ -d "$baseline" ]] \
        || die "Baseline sysroot missing: $baseline"

    if [[ -e "$destination" || -L "$destination" ]]; then
        (( overwrite == 1 )) \
            || die "Dependency sysroot exists: $destination; use --overwrite"
    fi

    mkdir -p -- "$(dirname -- "$destination")" \
        || die "Cannot create dependency sysroot directory"
    
    temporary=$(mktemp -d "${destination}.tmp.XXXXXX") \
        || die "Cannot create temporary dependency sysroot"

    trap 'rm -rf -- "$temporary"' EXIT

    echo "[....] Copying baseline sysroot...."
    cp -a --reflink=auto -- "$baseline/." "$temporary/" \
        || die "Cannot copy baseline sysroot"

    for dependency in "${build_order[@]}"; do
        [[ "$dependency" != "$requested" ]] || continue

        archive=$(package_archive_path "$dependency") \
            || die "Cannot locate package archive: $dependency"

        [[ -f "$archive" ]] \
            || die "Build dependency archive missing: $dependency"

        echo "[....] Adding dependency: $dependency"

        tar --zstd \
            --extract \
            --no-same-owner \
            --file="$archive" \
            --directory="$temporary" \
            || die "Cannot extract dependency: $dependency"
    done

    if [[ -e "$destination" || -L "$destination" ]]; then
        rm -rf -- "$destination" \
            || die "Cannot replace dependency sysroot"
    fi

    mv -T -- "$temporary" "$destination" \
        || die "Cannot finalize dependency sysroot"
)

# ----- Core Functions ----- #
build_pkg() (
    local name=$1
    local overwrite=$2
    local source_type=archive patch_subdir=patches
    local -a patches=() bld_deps=() host_deps=()
    local filename='' archive=''

    local recipe_dir="$RECIPE_DIR/$name"
    local recipe="$recipe_dir/$name.btr"
    local files_dir="$recipe_dir/fs"
    [[ -f "$recipe" ]] || die "Package '$name' does not have a BTR."
    source "$recipe"

    check_host_deps "${host_deps[@]}"

    local source_dir="$WORK_DIR/$name-$version"
    local staging_dir="$STAGING_DIR/$name-$version-$release"
    local package_file="$PKG_DIR/$name-$version-$release.$TARGET.tar.zst"
    local log_file="$WORK_DIR/$name-$version-$release.log"
    local dependency_sysroot="$WORK_DIR/sysroots/$name"
    
    mkdir -p -- "$WORK_DIR" \
        || die "Cannot create package work directory"

    if [[ -e "$package_file" || -L "$package_file" ]]; then
        if (( overwrite == 0 )); then
            die "Package already exists: $package_file; use --overwrite"
        fi
    fi

    local directory
    for directory in "$source_dir" "$staging_dir" "$dependency_sysroot"; do
        if [[ -e "$directory" || -L "$directory" ]]; then
            if (( overwrite == 0 )); then
                die "Already exists: $directory; use --overwrite to rebuild"
            fi
        fi
    done

    case "$source_type" in
        archive)
            [[ -n "${url-}" && -n "${shasum-}" ]] \
                || die "Archive recipe requires url and shasum: $name"

            build_env

            filename="${url%%\?*}"
            filename="${filename##*/}"
            archive="$SOURCES_DIR/$filename"
    
            fetch_source "$url" "$archive" "$shasum"
            ;;
        local) ;;
        *)
            die "Unsupported source type: $source_type"
            ;;
    esac

    if (( overwrite == 1 )); then
        echo "[....] Removing previous build and staging files for $name"
        rm -rf -- "$source_dir" "$staging_dir" \
            || die "Cannot remove previous package build"
    fi

    : > "$log_file"

    if [[ "$source_type" == archive ]]; then
        extract_source "$archive" "$source_dir"
    else
        mkdir -p -- "$source_dir" \
            || die "Cannot create package work directory"
    fi

    mkdir -p -- "$staging_dir" \
        || die "Cannot create staging directory: $staging_dir"

    cd -- "$source_dir" \
        || die "Cannot enter source directory: $source_dir"

    apply_patches "$recipe_dir/$patch_subdir" "${patches[@]}"

    if [[ "$source_type" == archive ]]; then
        prepare_dependency_sysroot "$name" "$dependency_sysroot" \
            2>&1 | tee -a "$log_file"

        export SYSROOT_DIR="$dependency_sysroot"
        export PKG_CONFIG_SYSROOT_DIR="$SYSROOT_DIR"
        export PKG_CONFIG_LIBDIR="$SYSROOT_DIR/usr/lib/pkgconfig:$SYSROOT_DIR/usr/share/pkgconfig"
        export PKG_CONFIG_PATH=
    fi

    local phase
    for phase in prerun_f configure_f build_f install_f postrun_f; do
        declare -F "$phase" >/dev/null \
            || die "Recipe '$name' is missing $phase"
    done

    if [[ "$source_type" == archive ]]; then
        ccache --zero-stats
    fi

    for phase in prerun_f configure_f build_f install_f postrun_f; do
        echo "[....] $name: $phase"
        "$phase"
    done 2>&1 | tee -a "$log_file"

    if [[ "$source_type" == archive ]]; then
        ccache --show-stats
    fi

    package_output "$staging_dir" "$package_file" \
        2>&1 | tee -a "$log_file"
)

clean_pkg() (
    local name=$1

    local recipe="$RECIPE_DIR/$name/$name.btr"
    [[ -f "$recipe" ]] || die "Package '$name' does not have a BTR."
    source "$recipe"

    local source_dir="$WORK_DIR/$name-$version"
    local staging_dir="$STAGING_DIR/$name-$version-$release"
    local dependency_sysroot="$WORK_DIR/sysroots/$name"

    echo "[....] Removing build and staging files for $name"
    rm -rf -- "$source_dir" "$staging_dir" "$dependency_sysroot" \
        || die "Cannot remove package build"
)

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
Build it first: ./build.sh build --target $target_arch --package $dep --format rpm"
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

    args=(--target "$target_arch" --define '_libdir /usr/lib' --define 'dist .natick')
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
format=btr
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
        --format)
            if (($# < 2)) || [[ $2 == -* ]]; then
                die "--format requires a value"
            fi
            format=$2
            shift 2
            ;;
        --format=*)
            format=${1#*=}
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
case "$format" in
    btr) ;;
    rpm)
        [[ "$package" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.+-]*$ ]] \
            || die "Invalid RPM package name: $package"
        ;;
    *) die "Unsupported build format: $format (expected btr or rpm)" ;;
esac

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

export TOOLCHAIN_DIR="${BUILDROOT}/${TARGET}/toolchain"
export SYSROOT_DIR="${BUILDROOT}/${TARGET}/sysroot"

export RECIPE_DIR="${SCRIPT_DIR}/pkg"
export SOURCES_DIR="${BUILDROOT}/src"

export ROOTFS_DIR="${OUTPUT_DIR}/${TARGET}/rootfs"
export WORK_DIR="${OUTPUT_DIR}/${TARGET}/work"
export STAGING_DIR="${OUTPUT_DIR}/${TARGET}/staging"
export PKG_DIR="${OUTPUT_DIR}/${TARGET}/packages"

case "$subcommand:$format" in
    build:rpm)
        build_rpm_pkg "$package" "$overwrite"
        ;;
    clean:rpm)
        clean_rpm_pkg "$package"
        ;;
    build:btr)
        resolve_build_order "$package"
        
        for planned_package in "${build_order[@]}"; do
            package_file=$(package_archive_path "$planned_package") \
                || die "Cannot determine archive for $planned_package"

            if [[ "$planned_package" == "$package" ]]; then
                build_pkg "$planned_package" "$overwrite"
            elif [[ -f "$package_file" ]]; then
                echo "[....] Reusing dependency: $planned_package"
            else
                echo "[....] Building dependency: $planned_package"
                build_pkg "$planned_package" 1
            fi
        done
        ;;
    clean:btr)
        clean_pkg "$package"
        ;;
esac