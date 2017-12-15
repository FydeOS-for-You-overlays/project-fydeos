# Copyright 2016-2017 Flint OS
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit git-2

DESCRIPTION="The daemon composed by nodejs and running on Flint OS. It provides the background support for Flint OS extensions."
EGIT_REPO_URI="git@git.flintos.xyz:cockpit/flint_daemon.git"
EGIT_BRANCH="master"
EGIT_COMMIT="e8af73eb72e39b0712bc73e3fde7def62c44ebd4"
HOMEPAGE="https://flintos.io/"

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

	# Build the obscured source and install them
	# Install necessary npm utilies needed to run following commands
	time npm install --only=dev || die
	npm run dist || die
	insinto /usr/share/flint_daemon
	doins -r dist/*

	# Install node_modules in the installed dir, this time only production dependencies
	cd ${ED}/usr/share/flint_daemon
	time npm install --only=production || die

	# Remove "scripts" section from package.json as it is not required at run time actually and may leak some our internal information
	jq 'del(.scripts)' package.json > tmp.$$.json &&
		mv tmp.$$.json package.json

	# Remove unnecessary files
	rm config/development.json
}
