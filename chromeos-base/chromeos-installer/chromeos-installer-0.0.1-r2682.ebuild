# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
CROS_WORKON_COMMIT="881f3321bf80f5cb7028e0e870591c3d5ba13d2f"
CROS_WORKON_TREE="e2269c44d323e85280117929aa2ce59ca03cf53f"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_DESTDIR="${S}"
CROS_WORKON_OUTOFTREE_BUILD=0

inherit cros-workon cros-debug libchrome systemd

DESCRIPTION="Chrome OS Installer"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="cros_host direncryption -mtd pam systemd test"

DEPEND="
	chromeos-base/verity
	mtd? ( dev-embedded/android_mtdutils )
	test? (
		dev-cpp/gmock[static-libs(+)]
		dev-cpp/gtest[static-libs(+)]
	)
	!cros_host? (
		chromeos-base/vboot_reference
	)"
RDEPEND="
	pam? ( app-admin/sudo )
	chromeos-base/libbrillo
	chromeos-base/vboot_reference
	dev-util/shflags
	sys-apps/rootdev
	sys-apps/util-linux
	sys-apps/which
	sys-fs/e2fsprogs"

src_unpack() {
	cros-workon_src_unpack
	S+="/installer"
}

src_prepare() {
	cros-workon_src_prepare

	epatch ${FILESDIR}/dual-boot.patch
	epatch ${FILESDIR}/dual-boot-postinst.patch
}

src_configure() {
	# need this to get the verity headers working
	append-cppflags -I"${SYSROOT}"/usr/include/verity/
	append-cppflags -I"${SYSROOT}"/usr/include/vboot
	append-ldflags -L"${SYSROOT}"/usr/lib/vboot32

	cros-workon_src_configure
}

src_compile() {
	# We don't need the installer in the sdk, just helper scripts.
	use cros_host && return 0

	USE_mtd=$(usev mtd) cros-workon_src_compile
	if use mtd; then
		USE_mtd=$(usev mtd) cw_emake -r nand_partition
	fi
}

src_test() {
	if ! use x86 && ! use amd64 ; then
		einfo Skipping unit tests on non-x86 platform
	else
		# Needed for `cros_run_unit_tests`.
		cros-workon_src_test
	fi
}

src_install() {
	cros-workon_src_install
	if use cros_host ; then
		dosbin chromeos-install
	else
		dobin "${OUT}"/cros_installer
		if use mtd ; then
			dobin "${OUT}"/nand_partition
		fi
		dosbin chromeos-* encrypted_import
		dosym usr/sbin/chromeos-postinst /postinst

		# Install init scripts.
		if use systemd; then
			systemd_dounit init/install-completed.service
			systemd_enable_service boot-services.target install-completed.service
			systemd_dounit init/crx-import.service
			systemd_enable_service system-services.target crx-import.service
		else
			insinto /etc/init
			doins init/*.conf
		fi
		insinto /usr/share/cros/init
		doins init/crx-import.sh
	fi

	insinto /usr/share/misc
	doins share/chromeos-common.sh
	if use direncryption; then
		sed -i '/local direncryption_enabled=/s/false/true/' \
			"${D}/usr/share/misc/chromeos-common.sh" ||
			die "Can not set directory encryption in common library"
	fi

	dosbin ${FILESDIR}/flintos-post-install.sh
}
