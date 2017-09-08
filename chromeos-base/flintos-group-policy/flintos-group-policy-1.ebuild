EAPI=4

DESCRIPTION="Flint OS group policies"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="flintos_editions_vanilla flintos_editions_dev_china flintos_editions_dev_intl flintos_editions_uk_customer"

DEPEND=""
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_install() {
	insinto /etc/chromium/policies/managed

	use flintos_editions_vanilla || newins ${FILESDIR}/flintos-${FLINTOS_EDITIONS}.json flintos.json
}
