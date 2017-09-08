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
