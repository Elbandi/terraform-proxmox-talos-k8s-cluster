#!/bin/sh
for DEVICE in $(cd /hostfs;ls dev/disk/by-id/scsi-*lvm* 2>/dev/null); do
  NAME=$(expr "$DEVICE" : '.*lvm-\([^\-]\+\)')
  DEVICE=$(realpath /hostfs/$DEVICE)
  if ! chroot /hostfs lvdisplay $NAME/pool &>/dev/null ; then
    echo "Creating $NAME-pool on ${DEVICE##/hostfs}."
    pvcreate --yes -ff ${DEVICE##/hostfs}
    vgcreate --yes $NAME ${DEVICE##/hostfs}
    lvcreate --yes -n MetadataLV -L 64M $NAME ${DEVICE##/hostfs}:0-31
    lvcreate --yes -n pool -l 100%FREE $NAME ${DEVICE##/hostfs}:32-
    lvconvert --yes --type thin-pool --poolmetadata MetadataLV $NAME/pool
  fi
  chroot /hostfs/ pvdisplay -m ${DEVICE##/hostfs}
done

if [ "x$1" = "xlabel" ]; then
    group()
    {
        awk '
        {
            key = $1
            val = $2
            if (key in data)
                data[key] = data[key] "," val
            else
                data[key] = val
        }
        END {
            for (k in data)
                print k, data[k]
        }
        '
    }

    mkdir -p /hostfs/etc/kubernetes/node-feature-discovery/features.d
    (
      vgs --noheadings  -o vg_name,pv_name|group|while read vg pv; do
        echo "lvm.vg.$vg=${pv#/dev/}"
      done
      lvs --noheadings -o lv_name,vg_name|group|while read lv vg; do
        echo lvm.lv.$lv=$vg
      done
    ) > /hostfs/etc/kubernetes/node-feature-discovery/features.d/lvm
fi
