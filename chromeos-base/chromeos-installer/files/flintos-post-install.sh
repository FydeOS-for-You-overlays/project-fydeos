#!/bin/bash

# INSTALL_ROOT is the a temp dir that the new root fs mounts under
INSTALL_ROOT=$1

# The new rootfs is mounted ro
mount -o remount,rw ${INSTALL_ROOT}

# Take care of dual boot
if grep -q -s "^FLINTOS_DUALBOOT=1$" /etc/flintos-release; then
	echo "Flint OS: taking care of dual boot related stuff..."
	${INSTALL_ROOT}/usr/sbin/dual-boot-install.sh -r ${INSTALL_ROOT}
fi

# Copy all customized files from old root fs
cp -af /etc/modprobe.d/flintos* ${INSTALL_ROOT}/etc/modprobe.d/

mount -o remount,ro ${INSTALL_ROOT}
# Dual boot stuff ends

# Remove stored VPD information
# Find out device name of the newly installed OEM partition
find_installed_oem_part() {
	local installed_disk_dev=$(rootdev -d ${INSTALL_ROOT})

	# The chromeos-install script puts a loopback device on top of the actual disk device
	if [[ ${installed_disk_dev} == /dev/loop* ]]; then
		installed_disk_dev=$(losetup -n -O BACK-FILE -l ${installed_disk_dev})
	fi

	local installed_oem_part=$(cgpt find -l OEM ${installed_disk_dev})
	echo ${installed_oem_part}
}

if [[ -n "$IS_INSTALL" || -n "$IS_RECOVERY_INSTALL" || -n "$IS_FACTORY_INSTALL" ]]; then
	echo "Flint OS: taking care of VPD related stuff..."

	vpd_file=${INSTALL_ROOT}/usr/share/oem/.vpd_info
	oem_part=$(find_installed_oem_part)

	# Remove the VPD file on OEM partition first.
	mount ${oem_part} ${INSTALL_ROOT}/usr/share/oem
	rm -f ${vpd_file}
	umount ${oem_part}

	# Also try remove it on the new rootfs because the flintsystem command may save VPD information
	# on rootfs if OEM partition is not available.
	rm -f ${vpd_file}
fi
# Remove stored VPD information ends
