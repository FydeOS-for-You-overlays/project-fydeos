# Copyright (c) 2017 The Flint OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

DESCRIPTION="A typical non-generic implementation will install any board-specific configuration files and drivers which are not suitable for inclusion in a generic board overlay."
HOMEPAGE="http://www.flintos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="flint_policy flint_daemon shadowsocks"

RDEPEND="
	!chromeos-base/chromeos-bsp-null
	sys-kernel/linux-firmware
	chromeos-base/flintos-arch-spec
	chromeos-base/flintos-chip-spec
	chromeos-base/flintos-board-spec
	chromeos-base/flintos-variant-spec
	chromeos-base/flintos-release
	flint_policy? ( chromeos-base/flintos-group-policy )
	flint_daemon? ( net-misc/flint_daemon )
	shadowsocks? ( net-proxy/shadowsocks-libev )
"
DEPEND="
	${RDEPEND}
"
