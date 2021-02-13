#!/bin/bash
#=========================#
# Natick Build System     #
#-------------------------#
# Main Executable script  #
# ISC License             #
#=========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# All Rights Reserved 
#=========================#

# --- Defined Variables --- #
BARCH="x86_64"		# Only variable user should control!

# --- Call external libs --- #
. lib/vars.sh
. lib/func.sh
. lib/btrs.sh

# --- Local Variables --- #
EXEC=$0
OPT=$1
PKG=$2

case "${OPT}" in
	toolchain )
		if [[ -d ${M_TOOLCHAIN} ]] && [[ -d ${M_SYSROOT} ]]; then
			lprint "Mussel for ${BARCH} already compiled." "done"
		else
			cd ${M_PROJECT}
			env -i bash -l -c "time ./mussel.sh ${BARCH} -p"
		fi
		mkdir ${N_WORK}
		;;
	build )
		# Check if user is root
		if [ "$EUID" -ne 0 ]; then
			lprint "Natick Build Script must be ran as root. To learn more, read help dialog." "fail"
		fi
		
		# Check if directories exist
		if [[ ! -d ${M_PREFIX} ]]; then
			lprint "Toolchain not generated. Generate with '${EXEC} toolchain'" "fail"
		fi
		if [[ ! -d ${N_WORK} ]]; then
			mkdir ${N_WORK}
		fi
		echo "TO BE IMPLEMENTED"
		;;
	clean )
		cd ${M_PROJECT}
		./mussel.sh -c
		lprint "Cleaning Natick Build Environment...." "...."
		rm -rf ${N_OUT} &> /dev/null
		rm -rf ${N_WORK} &> /dev/null
		rm ${LOG} &> /dev/null
		lprint "Cleaned Natick Build Environment." "done"
		;;
	"" | * )
		lusage
		;;
esac

