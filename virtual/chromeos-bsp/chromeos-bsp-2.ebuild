# Copyright (c) 2017 The Flint OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

DESCRIPTION="A typical non-generic implementation will install any board-specific configuration files and drivers which are not suitable for inclusion in a generic board overlay."
HOMEPAGE="http://www.flintos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="flintos_editions_vanilla flintos_editions_dev_china flintos_editions_dev_intl flintos_editions_uk_customer flintos_editions_local"

RDEPEND="
	!chromeos-base/chromeos-bsp-null
	sys-kernel/linux-firmware
	chromeos-base/flintos-arch-spec
	chromeos-base/flintos-chip-spec
	chromeos-base/flintos-board-spec
	chromeos-base/flintos-variant-spec
	!flintos_editions_vanilla? (
		chromeos-base/flintos-group-policy
		net-misc/flint_daemon
		net-proxy/shadowsocks-libev
	)
	chromeos-base/flintos-release
"
DEPEND="
	${RDEPEND}
"
