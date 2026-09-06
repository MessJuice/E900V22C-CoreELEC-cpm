#!/bin/sh
# 确保以 root 执行，或 sudo ./build.sh

version="21.3-Omega"
source_img="CoreELEC-Amlogic-ng.arm-${version}-Generic.img.gz"
img=${source_img%.gz}
url="https://github.com/CoreELEC/CoreELEC/releases/download/${version}/${source_img}"
target="CoreELEC-Amlogic-ng.arm-${version}-E900V22C-$(date +%Y.%m.%d).img"
mount="target"
common="common-files"

# 准备阶段
wget -O ${source_img} ${url}
gunzip ${source_img}
mkdir -p ${mount}

# 处理 boot 分区
mount -o loop,offset=4194304 ${img} ${mount}
cp ${common}/e900v22c.dtb ${mount}/dtb.img

# 处理 SYSTEM 分区
unsquashfs -d SYSTEM-root ${mount}/SYSTEM
install -m 0644 ${common}/wifi_dummy.conf SYSTEM-root/usr/lib/modules-load.d/
install -m 0644 ${common}/sprd_sdio-firmware-aml.service SYSTEM-root/usr/lib/systemd/system/
install -m 0755 ${common}/fs-resize SYSTEM-root/usr/lib/libreelec/
install -m 0644 ${common}/rc_maps.cfg SYSTEM-root/usr/config/
install -m 0644 ${common}/e900v22c.rc_keymap SYSTEM-root/usr/config/rc_keymaps/
install -m 0644 ${common}/keymap.hwdb SYSTEM-root/usr/config/hwdb.d/
ln -s ../sprd_sdio-firmware-aml.service SYSTEM-root/usr/lib/systemd/system/multi-user.target.wants/
mksquashfs SYSTEM-root SYSTEM -comp lzo -Xalgorithm lzo1x_999 -Xcompression-level 9 -b 524288 -no-xattrs
rm ${mount}/SYSTEM.md5
dd if=/dev/zero of=${mount}/SYSTEM bs=4M || true
sync
rm ${mount}/SYSTEM
mv SYSTEM ${mount}/SYSTEM
md5sum ${mount}/SYSTEM > ${mount}/SYSTEM.md5
rm -rf SYSTEM-root
umount ${mount}

# 处理 data 分区
mount -o loop,offset=541065216 ${img} ${mount}
mkdir -p ${mount}/.kodi/userdata/keymaps
install -m 0644 ${common}/advancedsettings.xml ${mount}/.kodi/userdata/
install -m 0644 ${common}/backspace.xml ${mount}/.kodi/userdata/keymaps/
umount ${mount}

# 生成新镜像
mv ${img} ${target}
gzip ${target}