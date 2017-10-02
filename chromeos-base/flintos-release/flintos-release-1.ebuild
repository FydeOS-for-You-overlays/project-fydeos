# Copyright (c) 2017 Flint Innovations Limited. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit flintos

DESCRIPTION="Flint OS release information file"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="flintos_editions_vanilla flintos_editions_dev_china flintos_editions_dev_intl flintos_editions_uk_customer flintos_editions_local"

DEPEND=""
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_install() {
	dodir /etc

	flintos_set_edition
	flintos_set_update_server
	flintos_set_dualboot_flag
}
