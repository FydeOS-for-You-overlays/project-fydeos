# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

CROS_WORKON_COMMIT="3686f3192def5015d68e59b64799cf68dbc2fc08"
CROS_WORKON_TREE="13229455359216f8d405a7093e93651ceecfb710"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_DESTDIR="${S}/platform2"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_OUTOFTREE_BUILD=0

PLATFORM_SUBDIR="installer"

inherit cros-workon platform systemd

DESCRIPTION="Chrome OS Installer"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="cros_embedded cros_host direncryption +mmc -mtd nvme pam +sata systemd test"

DEPEND="
	chromeos-base/verity
	mtd? ( dev-embedded/android_mtdutils )
	!cros_host? (
		chromeos-base/vboot_reference
	)"
RDEPEND="
	pam? ( app-admin/sudo )
	chromeos-base/libbrillo
	chromeos-base/vboot_reference
	dev-util/shflags
	sys-apps/rootdev
	!cros_embedded? (
		sata? ( sys-apps/hdparm )
		sata? ( sys-apps/smartmontools )
		nvme? ( sys-apps/smartmontools )
		mmc? ( sys-apps/mmc-utils )
	)
	sys-apps/util-linux
	sys-apps/which
	sys-fs/e2fsprogs"

platform_pkg_test() {
	platform_test "run" "${OUT}/cros_installer_unittest"
	platform_test "run" "test/storage_info_unit_test"
}

src_unpack() {
	platform_src_unpack

	cd ${S}
	epatch ${FILESDIR}/dual-boot.patch
	epatch ${FILESDIR}/dual-boot-postinst-r63.patch
}

src_install() {
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
	if ! use cros_embedded; then
		doins share/storage-info-common.sh
	fi
	if use direncryption; then
		sed -i '/local direncryption_enabled=/s/false/true/' \
			"${D}/usr/share/misc/chromeos-common.sh" ||
			die "Can not set directory encryption in common library"
	fi

	dosbin ${FILESDIR}/flintos-post-install.sh
}
