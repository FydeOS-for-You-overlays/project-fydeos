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


# @FUNCTION: flintos_update_server
# @DESCRIPTION:
# Append Flint OS update server values to the /etc/flintos-release file according to the FLINTOS_EDITIONS flag.
# It must be run after the flintos_set_update_server function
flintos_set_update_server() {
	local edition=${FLINTOS_EDITIONS}

	local rel="${ED}/etc/flintos-release"
	[[ ! -e "${rel}" ]] && die "/etc/flintos-release file missing. Run flintos_set_edition first."

	cat <<-EOF >> "${rel}"
	FLINTOS_AUSERVER=https://up.flintos.xyz/${edition}/update
	EOF
	#FLINTOS_DEVSERVER=https://up.flintos.xyz/${edition}
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
