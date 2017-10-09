#!/bin/bash

# INSTALL_ROOT is the a temp dir that the new root fs mounts under
INSTALL_ROOT=$1

# The new rootfs is mounted ro
mount -o remount,rw ${INSTALL_ROOT}

# Take care of dual boot
if grep -q -s "^FLINTOS_DUALBOOT=1$" /etc/flintos-release; then
	${INSTALL_ROOT}/usr/sbin/dual-boot-install.sh -r ${INSTALL_ROOT}
fi

# Copy all customized files from old root fs
cp -af /etc/modprobe.d/flintos* ${INSTALL_ROOT}/etc/modprobe.d/


mount -o remount,ro ${INSTALL_ROOT}
