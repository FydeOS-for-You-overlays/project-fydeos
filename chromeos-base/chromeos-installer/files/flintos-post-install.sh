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

# Find out device name of a newly installed partition according to its label
find_installed_part() {
	local label=$1
	local installed_disk_dev=$(rootdev -d ${INSTALL_ROOT})

	# The chromeos-install script puts a loopback device on top of the actual disk device
	if [[ ${installed_disk_dev} == /dev/loop* ]]; then
		installed_disk_dev=$(losetup -n -O BACK-FILE -l ${installed_disk_dev})
	fi

	local installed_part=$(cgpt find -l $label ${installed_disk_dev})
	echo ${installed_part}
}

# Remove stored VPD information from the newly installed system
remove_stored_vpd() {
	echo "Flint OS: taking care of VPD related stuff..."

	local vpd_file=${INSTALL_ROOT}/usr/share/oem/.vpd_info
	local oem_part=$(find_installed_part OEM)

	# Remove the VPD file on OEM partition first.
	mount ${oem_part} ${INSTALL_ROOT}/usr/share/oem
	rm -f ${vpd_file}
	umount ${oem_part}

	# Also try remove it on the new rootfs because the flintsystem command may save VPD information
	# on rootfs if OEM partition is not available.
	rm -f ${vpd_file}
}

# The stateful partition is already expanded to fill the spare space on disk when the OS is installed
# to the disk, so auto-expand-partition is no longer required to run
disable_stateful_auto_expand() {
	echo "Flint OS: disabling auto-expand-partition service..."

	local flag_file=${INSTALL_ROOT}/mnt/stateful_partition/.autoexpanded
	local stateful_part=$(find_installed_part STATE)

	# Create the flag file so the auto-expand-partition service will not run
	mount ${stateful_part} ${INSTALL_ROOT}/mnt/stateful_partition
	touch ${flag_file}
	umount ${stateful_part}
}

if [[ -n "$IS_INSTALL" || -n "$IS_RECOVERY_INSTALL" || -n "$IS_FACTORY_INSTALL" ]]; then
	remove_stored_vpd
	disable_stateful_auto_expand
fi
