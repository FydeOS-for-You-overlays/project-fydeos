EAPI=4

DESCRIPTION="Flint OS group policies"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="flintos_editions_vanilla flintos_editions_dev_china flintos_editions_dev_intl"

DEPEND=""
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_install() {
	insinto /etc/chromium/policies/managed

	if use flintos_editions_dev_china; then
		newins ${FILESDIR}/flintos-dev_china.json flintos.json
	elif use flintos_editions_dev_intl; then
		newins ${FILESDIR}/flintos-dev_intl.json flintos.json
	fi
}
