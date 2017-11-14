# Copyright (c) 2017 Flint Innovations Limited. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: flintos.eclass
# @MAINTAINER:
# Kai Liu <kraml@flintos.io>
# @BLURB: Eclass for Flint OS specific tasks
#
#
# @FUNCTION: flintos_set_edition
# @DESCRIPTION:
# Initialize the /etc/flintos-release file with Flint OS edition string according to FLINTOS_EDITIONS flag.
flintos_set_edition() {
	local edition=${FLINTOS_EDITIONS}

	dodir /etc

	local rel="${ED}/etc/flintos-release"
	[[ -e ${rel} ]] && die "${rel} already exists!"

	cat <<-EOF > "${rel}" || die "creating ${rel} failed!"
	FLINTOS_EDITION=${edition}
	EOF
}


# @FUNCTION: flintos_set_update_server
# @DESCRIPTION:
# Append Flint OS update server values to the /etc/flintos-release file according to the FLINTOS_EDITIONS flag.
# It must be run after the flintos_set_edition function
flintos_set_update_server() {
	local rel="${ED}/etc/flintos-release"
	[[ ! -e "${rel}" ]] && die "/etc/flintos-release file missing. Run flintos_set_edition first."

	cat <<-EOF >> "${rel}"
	FLINTOS_AUSERVER=https://up.flintos.xyz/service/update2
	EOF
}


# @FUNCTION: flintos_set_dualboot_flag
# @DESCRIPTION:
# Append a line of FILNTOS_DUALBOOT=0 to the file /etc/flintos-release. The FLINTOS_DUALBOOT variable is used
# to indicate whether current system is installed in dual boot mode. It is always set to 0 in the beginning,
# only changed to 1 if the system is installed to the disk by the dual boot installer.
# It must be run after the flintos_set_edition function
flintos_set_dualboot_flag() {
	local rel="${ED}/etc/flintos-release"
	[[ ! -e "${rel}" ]] && die "/etc/flintos-release file missing. Run flintos_set_edition first."

	cat <<-EOF >> "${rel}"
	FLINTOS_DUALBOOT=0
	EOF
}


# @FUNCTION: flintos_remove_firmware
# @USAGE: <directory>
# @DESCRIPTION:
# Remove firmware files that are suspicious to license issues. Accept an argument as the top directory to look for and remove those files.
flintos_remove_firmware() {
	local prefix=$1

	fw_list="
		acenic/tg1.bin
		acenic/tg2.bin
		adaptec/starfire_rx.bin
		adaptec/starfire_tx.bin
		atmsar11.fw
		cpia2/stv0672_vp4.bin
		edgeport/boot.fw
		edgeport/down.fw
		edgeport/down2.fw
		edgeport/down3.bin
		edgeport/boot2.fw
		emi62/midi.fw
		emi62/spdif.fw
		emi62/bitstream.fw
		emi62/loader.fw
		ess/maestro3_assp_minisrc.fw
		ess/maestro3_assp_kernel.fw
		intelliport2.bin
		keyspan/usa49w.fw
		keyspan/usa19w.fw
		keyspan/usa49wlc.fw
		keyspan/usa28xb.fw
		keyspan/usa19qw.fw
		keyspan/usa28.fw
		keyspan/usa19.fw
		keyspan/usa28xa.fw
		keyspan/mpr.fw
		keyspan/usa19qi.fw
		keyspan/usa18x.fw
		keyspan/usa28x.fw
		korg/k1212.dsp
		lgs8g75.fw
		mts_mt9234mu.fw
		mts_mt9234zba.fw
		myricom/lanai.bin
		ositech/Xilinx7OD.bin
		qlogic/12160.bin
		qlogic/1040.bin
		qlogic/isp1000.bin
		qlogic/1280.bin
		sb16/ima_adpcm_init.csp
		sb16/ima_adpcm_capture.csp
		sb16/mulaw_main.csp
		sb16/ima_adpcm_playback.csp
		sb16/alaw_main.csp
		sun/cassini.bin
		ti_3410.fw
		ti_5052.fw
		ttusb-budget/dspbootcode.bin
		vicam/firmware.fw
	"

	einfo "Removing firmware files that are suspicious to license issues..."
	local file_list=""
	for fw_file in ${fw_list}; do
		file_list+=" ${prefix}/${fw_file}"
	done
	rm -f ${file_list}


	einfo "Removing empty directories after removed firmware files..."
	find ${prefix} -type d -empty -delete

}


# @FUNCTION: flintos_checkout_local_chrome_source
# @DESCRIPTION:
# Checkout local Chrome source code for the chrome ebuild
flintos_checkout_local_chrome_source() {
	# Below environment variables can be set to control the logic of this function
	# SKIP_SYNC
	#     if set with any value, build from existing source directly without fetching from server at all.
	# VER_TO_BUILD
	#     if set with an valid tag/branch/commit ID in the git repo, checkout an build that version.
	#     This takes precedence over the FLINTOS_EDITIONS use flag

	if [[ -n ${SKIP_SYNC} ]]; then
		elog "SKIP_SYNC is set, build from local source in ${CHROME_ROOT} directory without fetching from server."
		return
	fi

	# Digest version information from ebuild PN.
	# The $PV could be in two possible formats:
	#   * 9999.a.b.c.d - a.b.c.d is a Chrome version. This type of PV means it's a Flint customized version.
	#   * a.b.c.d - this type of PV means it is a vanilla version. In such case this function only helps to build from the local source.
	local ver_array=(${PV//./ })
	if [[ ${ver_array[0]} != "9999" ]]; then
		local CR_VERSION=${ver_array[0]}.${ver_array[1]}.${ver_array[2]}.${ver_array[3]}
	else
		local CR_VERSION=${ver_array[1]}.${ver_array[2]}.${ver_array[3]}.${ver_array[4]}
	fi

	# This allows overriding VER_TO_BUILD from env. var
	if [[ -z ${VER_TO_BUILD} ]]; then
		if use flintos_editions_vanilla; then
			local VER_TO_BUILD=${CR_VERSION}
			local VER_OVERRIDE=" (Vanilla Edition)"
		elif [[ ${ver_array[0]} != "9999" ]]; then
			local VER_TO_BUILD=${CR_VERSION}
			local VER_OVERRIDE=" (Not 9999 ebuild)"
		else
			local VER_TO_BUILD=flint_release_r${CR_VERSION}
			local VER_OVERRIDE=""
		fi
	else
		local VER_OVERRIDE=" (Overridden from environment)"
	fi

	elog "Version Informatin:
  Ebuild Version   = ${PV}
  Chromium Version = ${CR_VERSION}
  Version to Build = ${VER_TO_BUILD}${VER_OVERRIDE}"

	elog "Changing dir to local source ${CHROME_ROOT}/src"
	cd ${CHROME_ROOT}/src

	# Retry 3 times
	elog "Make sure we have all the release tag information in our local source ..."
	git fetch --tags --prune ||
	git fetch --tags --prune ||
	git fetch --tags --prune ||
	die "Failed to fetch from remote repository."

	# Known versions can be seen with 'git show-ref --tags'
	elog "Checking out Chromium code of version ${VER_TO_BUILD} ..."
	git checkout --force ${VER_TO_BUILD} ||
	git checkout --force ${VER_TO_BUILD} ||
	git checkout --force ${VER_TO_BUILD} ||
	die "Cannot checkout the designated version ${VER_TO_BUILD}, you may have specified a wrong version."

	# A pull is necessary if VER_TO_BUILD is a branch, above checkout will not update local work space from remote.
	# Howver if VER_TO_BUILD is a tag or a commit ID, then the pull will always fail because merge or rebase on a
	# tag makes no sense.
	if git show-ref -q --verify refs/heads/${VER_TO_BUILD}; then # It's a branch
		elog "Pull the latest code of branch ${VER_TO_BUILD} ..."
		git pull --rebase ||
		git pull --rebase ||
		git pull --rebase ||
		die "Cannot pull branch ${VER_TO_BUILD}, you may have network issue."
	fi

	elog "Syncing all deps of Chromium version ${VER_TO_BUILD} ..."
	${EGCLIENT} sync -r ${VER_TO_BUILD} --jobs 16 --with_branch_heads --with_tags --delete_unversioned_trees --reset --nohooks --force ||
	${EGCLIENT} sync -r ${VER_TO_BUILD} --jobs 16 --with_branch_heads --with_tags --delete_unversioned_trees --reset --nohooks --force ||
	${EGCLIENT} sync -r ${VER_TO_BUILD} --jobs 16 --with_branch_heads --with_tags --delete_unversioned_trees --reset --nohooks --force ||
	die "Sync deps failed, please retry."
}
