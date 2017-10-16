# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils systemd

DESCRIPTION="A lightweight secured SOCKS5 proxy for embedded devices and low end boxes"
HOMEPAGE="https://github.com/shadowsocks/shadowsocks-libev"

SRC_URI="https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"
IUSE="debug -doc"
RESTRICT="mirror"

RDEPEND="
	app-misc/jq
	net-libs/mbedtls
	>=dev-libs/libsodium-1.0.8
	dev-libs/libev
	net-firewall/ipset
	net-libs/udns
	dev-libs/libpcre
"
DEPEND="${RDEPEND}
	sys-kernel/linux-headers
	doc? (
		app-text/asciidoc
		app-text/xmlto
	)
"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myconf=" \
		$(use_enable debug assert) \
	"
	use doc || myconf+="--disable-documentation"
	econf ${myconf}
}

src_install() {
	default
	prune_libtool_files --all

	dodir "/etc/${PN}"
	insinto "/etc/${PN}"
	newins "${FILESDIR}/shadowsocks.json" shadowsocks.json

	newinitd "${FILESDIR}/shadowsocks.initd" shadowsocks
	dosym /etc/init.d/shadowsocks /etc/init.d/shadowsocks.server
	dosym /etc/init.d/shadowsocks /etc/init.d/shadowsocks.client
	dosym /etc/init.d/shadowsocks /etc/init.d/shadowsocks.redir
	dosym /etc/init.d/shadowsocks /etc/init.d/shadowsocks.tunnel

	dodoc -r acl

	systemd_newunit "${FILESDIR}/${PN}-local_at.service" "${PN}-local@.service"
	systemd_newunit "${FILESDIR}/${PN}-server_at.service" "${PN}-server@.service"
	systemd_newunit "${FILESDIR}/${PN}-redir_at.service" "${PN}-redir@.service"
	systemd_newunit "${FILESDIR}/${PN}-tunnel_at.service" "${PN}-tunnel@.service"

	# Generate chnroute.txt file
	curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' \
		| grep ipv4 \
		| grep CN \
		| awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' \
		> ${ED}/etc/${PN}/chnroute.txt \
		|| die

	insinto /etc/init
	doins ${FILESDIR}/ss-local.conf
	doins ${FILESDIR}/ss-redir.conf
}

pkg_setup() {
	elog "You need to choose the mode"
	elog "  server: rc-update add shadowsocks.server default"
	elog "  client: rc-update add shadowsocks.client default"
	elog "  redir:  rc-update add shadowsocks.redir default"
	elog "  tunnel: rc-update add shadowsocks.tunnel default"
}
