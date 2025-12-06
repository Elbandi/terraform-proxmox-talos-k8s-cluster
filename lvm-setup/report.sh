#!/bin/sh

set -x

while sleep 60; do
  echo ----------------------------------------
  date
  for DEVICE in $(cd /hostfs;ls dev/disk/by-id/scsi-*lvm* 2>/dev/null); do
    chroot /hostfs/ pvdisplay -m /$DEVICE
  done
done
