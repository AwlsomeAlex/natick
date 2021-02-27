#!/bin/bash
#=========================#
# Natick Build System     #
#-------------------------#
# Build library script    #
# ISC License             #
#=========================#
# Copyright (C) 2020-2021 Alexander Barris (AwlsomeAlex)
# alex@awlsome.com
# All Rights Reserved 
#=========================#

#=========================#
# Initialize Package Area #
#=========================#
pinit() {
	# --- Create Package Work Directory--- #
	if [[ ! -d ${N_PKG}/${PKG} ]]; then
		lprint "The specified package, ${PKG}, does not exist in the source repository." "fail"
	fi
	if [[ -d ${N_WORK}/${PKG} ]]; then
		lprint "The specified package, ${PKG}, appears to already been built." "warn"
		read -p "Rebuild? (Y/n): " opt
		if [[ ${opt} == "Y" ]]; then
			rm -rf ${N_WORK}/${PKG}/{build,root,vz}
			echo ""
		else
			lprint "Good call." "fail"
		fi
	fi
	mkdir -p ${N_WORK}/${PKG}
}

#======================#
# Prepare Package Area #
#======================#
pprep() {
	# --- Package Generation Hierarchy --- #
	vdef
	mkdir -p ${B_BUILDDIR} ${B_SOURCEDIR} ${B_BUILDROOT} ${B_VANZILE}

	# --- Check for Package Build Dependencies --- #
	for p in "${pkg_bld[@]}"; do
		if [[ ! -d ${N_WORK}/${p} ]]; then
			lprint "Dependency ${p} not built. Please build with '${EXEC} build ${p}'." "fail"
		fi
	done

	# --- Download Sources --- #
	for i in "${!pkg_src[@]}"; do
        l_src="${pkg_src[i]}"
        l_sum="${pkg_chk[i]}"
        l_archive=${l_src##*/}
        lprint "Downloading and Extracting ${l_archive}...." "...."
		if [[ ! -f ${B_SOURCEDIR}/${l_archive} ]]; then
        	(cd ${B_SOURCEDIR} && curl -LJO ${l_src})
		fi
        (cd ${B_SOURCEDIR} && echo "${l_sum}  ${l_archive}" | sha256sum -c -) > /dev/null || lprint "Bad Checksum: ${l_archive}: ${l_sum}" "fail"
        pv ${B_SOURCEDIR}/${l_archive} | bsdtar xf - -C ${B_BUILDDIR}/
        lprint "Downloaded and Extracted ${l_archive}." "done"
    done
}