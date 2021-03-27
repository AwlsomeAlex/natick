#!/bin/bash
#===========================#
# natickOS Build System     #
#---------------------------#
# Main Executable script    #
# ISC License               #
#===========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# All Rights Reserved 
#===========================#
set -eE -o functrace

# --- Defined Variables --- #
BARCH="i686"		# Only variable user should control!

# --- Call external libs --- #
. lib/vars.sh
. lib/func.sh
. lib/btrs.sh

# --- Local Variables --- #
EXEC=$0
OPT=$1
PKG=$2

# --- Check for Toolchain --- #
if [[ ! -f ${M_PROJECT}/mussel.sh ]]; then
	lprint "mussel not found. Did you clone without --recursive?" "fail"
fi

# --- Basically the main function --- #
case "${OPT}" in
	check )
		lcheck
		;;
	toolchain )
		if [[ -d ${M_TOOLCHAIN} ]] && [[ -d ${M_SYSROOT} ]]; then
			lprint "Mussel for ${BARCH} already compiled." "done"
		else
			cd ${M_PROJECT}
			env -i bash -l -c "time ./mussel.sh ${BARCH} -p -l -k"
		fi
		mkdir ${N_WORK}
		;;
	build )
		echo ""
		ltitle 
		
		# Check if directories exist
		if [[ ! -d ${M_PREFIX} ]]; then
			lprint "Toolchain not generated. Generate with '${EXEC} toolchain'" "fail"
		fi
		if [[ ! -d ${N_WORK} ]]; then
			mkdir ${N_WORK}
		fi
		if [[ ! -d ${N_OUT} ]]; then
			mkdir ${N_OUT}
		fi
		# Initialize and source
		pinit
		trap 'failure ${LINENO} "$BASH_COMMAND"' ERR
		source ${N_PKG}/${PKG}/${PKG}.btr
		vdef
		vprint &>> ${LOG}
		pprep
		cd ${B_BUILDDIR}
		lprint "Compiling ${PKG}...." "...."
		build &>> ${LOG}
		lprint "Packaging ${PKG}...." "...."
		ppack
		lprint "${PKG} has been compiled and packaged." "done"
		;;
	run )
		if [[ ! -f ${N_OUT}/natickOS.iso ]]; then
			lprint "natickOS ISO not generated. Please generate with ./geniso.sh" "fail"
		else
			lprint "Starting natickOS in QEMU...." "...."
			if [[ ${BARCH} == "x86_64" ]]; then
				qemu-system-x86_64 -boot d -cdrom ${N_OUT}/natickOS-${BARCH}.iso -m 512
			elif [[ ${BARCH} == "i686" ]]; then
				qemu-system-i386 -boot d -cdrom ${N_OUT}/natickOS-${BARCH}.iso -m 512
			else
				lprint "Invalid Architecture: ${BARCH}" "fail"
			fi
		fi
		lprint "QEMU Finished." "done"
		;;
	clean )
		cd ${M_PROJECT}
		if [[ ${PKG} != "--skip-toolchain" ]]; then
			./mussel.sh -c
		fi
		lprint "Cleaning natickOS Build Environment...." "...."
		rm -rf ${N_OUT} &> /dev/null
		rm -rf ${N_WORK} &> /dev/null
		rm ${LOG} &> /dev/null
		lprint "Cleaned natickOS Build Environment." "done"
		;;
	"" | * )
		lusage
		;;
esac
