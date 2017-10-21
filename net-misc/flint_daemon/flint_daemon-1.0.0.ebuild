# Copyright 2016-2017 Flint OS
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit git-2

DESCRIPTION="The daemon composed by nodejs and running on Flint OS. It provides the background support for Flint OS extensions."
EGIT_REPO_URI="git@git.flintos.xyz:cockpit/flint_daemon.git"
EGIT_BRANCH="master"
EGIT_COMMIT="5347ce70fb9c1d721159eb8020394783bd4e9a8e"
HOMEPAGE="http://www.flintos.io/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RESTRICT="network-sandbox"

RDEPEND="net-libs/nodejs"
DEPEND="${RDEPEND}"

src_install() {
	insinto /etc/init
	doins ${FILESDIR}/flint_daemon.conf

	insinto /usr/share/flint_daemon
	npm run dist || die
	doins -r dist/*

	cd ${ED}/usr/share/flint_daemon
	npm install || die
}
