#!/bin/bash
#// Copyright 2020 The FydeOS Authors. All rights reserved.
#// Use of this source code is governed by a BSD-style license that can be
#// found in the LICENSE file.
OEM_PATH=/usr/share/oem
LICENSE_ID=license_id
EXPIRE_DATE=expire_date
LICENSE_TYPE=license_type
SERIAL_NUMBER=serial_number
LICENSE=license

license_readable_attrs=(
  $LICENSE_ID
  $EXPIRE_DATE
  $LICENSE_TYPE
  $LICENSE
)

license_writable_attrs=(
  $EXPIRE_DATE
  $LICENSE_TYPE
  $LICENSE
)

get_fix_devices() {
 lsblk -d -p -o NAME,TRAN,SUBSYSTEMS 2>/dev/null | \
  grep -i "\<nvme\> \| \<sata\> \| \<mmc" | \
  grep -v usb | \
  sed 's/\s.*$//' | \
  sort -r
}

get_device_serial() {
  lsblk -d $1 -o SERIAL -n  
}

get_disk_uuid() {
  fdisk -l $1 2>/dev/null | grep "Disk identifier:" | sed 's/^.*:\s//'
}

get_device_id() {
  local device=$1
  local id=$(get_device_serial $device)
  if [ -z "$id" ]; then
    id=$(get_disk_uuid $device)
  fi
  echo $id  
}

get_fix_id() {
  local id=""
  for device in $(get_fix_devices); do
      id=$(get_device_id $device)
      if [ -n "$id" ]; then
        echo $id
        return
      fi
  done
  exit 1
}

get_serial_num() {
  vpd -i RO_VPD -g $SERIAL_NUMBER 2>/dev/null 
}

create_id() {
  local id=$(get_serial_num)
  id+=$(get_fix_id)
  echo $id | sha1sum | sed "s/\s*.$//"
}

remount_oem_writable() {
  mount -o remount,rw "$OEM_PATH"
}

get_vpd_value() {
  vpd -i RW_VPD -g $1 2>/dev/null  
}

count_chars() {
  printf $1 | wc -c
}

put_vpd_value() {
  local varname=$1
  local value=$2
  vpd -i RW_VPD -p $(count_chars $value) -s "${varname}=${value}"
}

read_license() {
  local lines
  for var in ${license_readable_attrs[@]}; do
    lines+="\"${var}\":\"$(get_vpd_value $var)\","
  done
  echo "{${lines%,}}"
}

is_writeable(){
  local target=$1
  for attr in ${license_writable_attrs[@]}; do
    if [ "$attr" == "$target" ]; then
      return 0
    fi
  done
  return 1
}

# parm: xxxx=xxxxxx [ xxxxx=xxxxxx ]
write_license() {
  local varname
  local value
  remount_oem_writable
  for var in $@; do
    varname=${var%%=*}
    value=${var#*=}
    if is_writeable $varname; then
      put_vpd_value $varname $value
    fi
  done
}

main() {
  if [ $# -lt 1 ]; then
    exit 1
  fi
  local cmd=$1
  shift
  case $cmd in
    id )  create_id ;;
    read ) read_license ;;
    write ) write_license $@ ;;
    *) echo "no found command:$cmd"; exit 1 ;;
  esac
}

main $@
