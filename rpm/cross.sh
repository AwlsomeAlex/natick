#!/usr/bin/env bash
set -euo pipefail

directory=$NATICK_CROSS_TOOLS
arch=${NATICK_TARGET%%-*}

# Compiler wrapper for 'cc' and 'cxx' allows for the spec files
# to stay generic and support both native and cross compilation
write_compiler_wrapper() {
    local name=$1 compiler=$2
    printf '#!/bin/bash\nexec ccache %q %q %q "$@"\n' \
        "$compiler" "--target=$NATICK_TARGET" "--sysroot=$NATICK_SYSROOT" > "$directory/$name"
    chmod 755 -- "$directory/$name"
}

# Similar to compiler wrapper, pkg-config wrapper allows spec
# to stay generic, but intercepts the SYSROOT and LIBDIR to
# point to the temporary sysroot constructed by the build script
write_pkg_config_wrapper() {
    local host_pkg_config
    host_pkg_config=$(command -v pkg-config) || { echo 'Missing build-host tool: pkg-config' >&2; exit 1; }
    printf '#!/bin/bash\nexport PKG_CONFIG_PATH= PKG_CONFIG_SYSROOT_DIR=%q PKG_CONFIG_LIBDIR=%q\nexec %q "$@"\n' \
        "$NATICK_SYSROOT" "$NATICK_SYSROOT/usr/lib/pkgconfig:$NATICK_SYSROOT/usr/share/pkgconfig" \
        "$host_pkg_config" > "$directory/pkg-config"
    chmod 755 -- "$directory/pkg-config"
}

# clang gets a wrapper for cross-compilation values (and reads ENVs)
# meson reads a cross.ini for cross-compilation values
# cmake reads toolchain.cmake for cross-compilation values
case "$1" in
    tools)
        write_compiler_wrapper cc "$CC"
        write_compiler_wrapper cxx "$CXX"
        ;;
    meson)
        write_pkg_config_wrapper
        cat > "$directory/cross.ini" <<EOF
[binaries]
c = '$directory/cc'
cpp = '$directory/cxx'
ar = '$AR'
strip = '$STRIP'
pkg-config = '$directory/pkg-config'

[host_machine]
system = 'linux'
cpu_family = '$arch'
cpu = '$arch'
endian = 'little'

[properties]
needs_exe_wrapper = true
sys_root = '$NATICK_SYSROOT'
pkg_config_libdir = ['$NATICK_SYSROOT/usr/lib/pkgconfig', '$NATICK_SYSROOT/usr/share/pkgconfig']
EOF
        ;;
    cmake)
        write_pkg_config_wrapper
        cat > "$directory/toolchain.cmake" <<'EOF'
set(CMAKE_SYSTEM_NAME Linux)
string(REGEX REPLACE "-.*$" "" CMAKE_SYSTEM_PROCESSOR "$ENV{NATICK_TARGET}")

set(CMAKE_C_COMPILER "${CMAKE_CURRENT_LIST_DIR}/cc")
set(CMAKE_CXX_COMPILER "${CMAKE_CURRENT_LIST_DIR}/cxx")
set(CMAKE_AR "$ENV{AR}")
set(CMAKE_RANLIB "$ENV{RANLIB}")
set(CMAKE_STRIP "$ENV{STRIP}")
set(CMAKE_LINKER "$ENV{LD}")

set(CMAKE_SYSROOT "$ENV{NATICK_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH "$ENV{NATICK_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(PKG_CONFIG_EXECUTABLE "${CMAKE_CURRENT_LIST_DIR}/pkg-config" CACHE FILEPATH "Target pkg-config wrapper")
EOF
        ;;
    *) echo "Unknown cross-build input: $1" >&2; exit 1 ;;
esac
