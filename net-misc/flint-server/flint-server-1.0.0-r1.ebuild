
# Copyright 2016-2017 Flint OS
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit git-2

DESCRIPTION="The server composed by nodejs and running on Flint OS. It provides the background support for Flint OS extensions."
EGIT_REPO_URI="git@git.flintos.xyz:cockpit/flint_server.git"
HOMEPAGE="http://www.flintos.io/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="net-libs/nodejs"
DEPEND="${RDEPEND}"

src_install() {
	insinto /etc/init
	doins ${FILESDIR}/flint-server.conf

	insinto /usr/share/flint_server
	npm run dist || die
	doins -r dist/*

	cd ${ED}/usr/share/flint_server
	npm install || die
}
