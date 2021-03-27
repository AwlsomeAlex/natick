#!/bin/bash
#===========================#
# natickOS Build System     #
#---------------------------#
# Burnt Tavern Recipe       #
# ISC License               #
#===========================#
# LiveCD Generator
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# alex@awlsome.com
# All Rights Reserved
#===========================#

# --- Packages To Include --- #
PKGS=("busybox" "musl" "linux" "midstreams" "syslinux")


# --- Call external libs --- #
. lib/vars.sh
. lib/func.sh
export PKG="iso"
vdef

ltitle

# --- Checks --- #
if [[ -d ${N_WORK}/iso ]]; then
    lprint "The ISO work directory seems to be occupied." "warn"
	read -p "Delete? (Y/n): " opt
	if [[ ${opt} == "Y" ]]; then
		rm -rf ${N_WORK}/iso/
		echo ""
	else
		lprint "Good call." "fail"
	fi
fi
mkdir -p ${N_WORK}/iso/sysroot
mkdir -p ${N_WORK}/iso/vanzille
mkdir -p ${N_WORK}/iso/boot

# --- Create the InitramFS --- #
lprint "Prearing InitramFS...." "...."
mkdir -p ${N_WORK}/iso/sysroot/{boot,dev,etc,mnt/root,proc,root,sys,tmp,usr/{bin,lib,sbin,share,include},run}
curr=$(pwd)
cd ${N_WORK}/iso/sysroot
ln -s usr/bin bin
ln -s usr/sbin sbin
ln -s usr/lib lib
cd ${curr}

# --- Populate the InitramFS --- #
lprint "Populating InitramFS...." "...."
for item in ${PKGS[@]}; do
    if [ ! -f ${N_OUT}/${item}-[0-9]*.tar.zst ]; then
        lprint "${item} not compiled. Please compile it with './nbs.sh build ${item}" "fail"
    else
        file="${N_OUT}/${item}-[0-9]*.tar.zst"
        tar -xf ${file} -C ${N_WORK}/iso/sysroot
    fi
done

# --- Clean Sysroot --- #
${XTARGET}-strip -g \
    ${N_WORK}/iso/sysroot/bin/* \
    ${N_WORK}/iso/sysroot/sbin/* \
    ${N_WORK}/iso/sysroot/lib/* \
    2>/dev/null &>> ${LOG}


# --- Generate InitramFS --- #
lprint "Generating InitramFS...." "...."
cd ${N_WORK}/iso/sysroot
find . | cpio -R root:root -H newc -o | xz -9 --check=none > ${N_WORK}/iso/vanzille/initramfs.xz
cd ${curr}

# --- Prepare Image --- #
lprint "Preparing Image...." "...."
mv ${N_WORK}/iso/sysroot/boot/linux-*.xz ${N_WORK}/iso/vanzille/linux.xz
cp -r ${N_WORK}/iso/sysroot/boot/* ${N_WORK}/iso/boot
rm -rf /tmp/natickOS-sysroot
mv ${N_WORK}/iso/sysroot /tmp/natickOS-sysroot
# ^^^ TEMPORARY ^^^^

# --- Generate Image --- #
lprint "Generating Image...." "...."
cd ${N_WORK}/iso
fakeroot xorriso -as mkisofs \
    -isohybrid-mbr boot/isolinux/isohdpfx.bin \
    -c boot/isolinux/boot.cat \
    -b boot/isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o ${N_OUT}/natickOS-${BARCH}.iso \
    . &>> ${LOG}


lprint "Image successfully generated! It can now be found in ${N_OUT}/natickOS-${BARCH}.iso!" "done"