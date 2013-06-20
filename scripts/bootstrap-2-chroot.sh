#!/bin/bash

BROOT=${BROOT-/root}
NETCONF=${BROOT}/netconfig
SCRIPTSDIR=$(cd $(dirname $0); cd ../; pwd)

# Installing the Gentoo Base System
env-update
source /etc/profile
emerge --sync --quiet
sed -i \
    -e "s/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" \
    -e "s/^#ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/" \
    /etc/locale.gen
locale-gen

# Configuring the Kernel (gentoo-sources-3.2.12)
cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
emerge -q '=sys-kernel/gentoo-sources-3.8.13'
emerge gentoo-sources -p | \
    egrep -o "gentoo-sources-[r0-9.-]+" | egrep -o "[0-9][r0-9.-]+" > \
    /kernel-version.txt

cd /usr/src/linux
cp $(find ${SCRIPTSDIR}/scripts/linux-config -type f | sort -nr | head -n 1) \
    .config
make oldconfig
make -j2
make modules_install -j2
cp arch/x86_64/boot/bzImage /boot/kernel-$(cat /kernel-version.txt)

# Configuring your System
sed -i \
    -e "s:/dev/BOOT:/dev/vda1:" \
    -e "s:/dev/SWAP:#/dev/vda2:" \
    -e "s:/dev/ROOT:/dev/vda3:" \
    -e "s:ext2:ext4:" \
    -e "s:ext3:ext4:" \
    /etc/fstab

cat >> /etc/conf.d/net <<EOM
config_eth0="$(cat ${NETCONF}/addr.txt) netmask $(cat ${NETCONF}/mask.txt) broadcast $(cat ${NETCONF}/bcast.txt)"
routes_eth0="default via $(cat ${NETCONF}/gw.txt)"
dns_servers_eth0="$(cat ${NETCONF}/resolv.txt)"
EOM
(cd /etc/init.d && ln -s net.lo net.eth0)
rc-update add net.eth0 default

# Installing Necessary System Tools
emerge -q -j2 rsyslog vixie-cron eix logrotate ntp "=sys-block/parted-2.3*" \
    ethtool grub
sed -i \
    -s 's|^NTPCLIENT_OPTS=\"-s -b -u \\|NTPCLIENT_OPTS=\"-b ntp1.sakura.ad.jp\"|' \
    -s 's|\t0.gentoo.pool.ntp.org 1.gentoo.pool.ntp.org \\||' \
    -s 's|\t2.gentoo.pool.ntp.org 3.gentoo.pool.ntp.org\"||'\
    /etc/conf.d/ntp-client
sed -i \
    -s 's|^server 0.gentoo.pool.ntp.org|server ntp1.sakura.ad.jp|' \
    -s 's|^server 1.gentoo.pool.ntp.org||' \
    -s 's|^server 2.gentoo.pool.ntp.org||' \
    -s 's|^server 3.gentoo.pool.ntp.org||' \
    /etc/ntp.conf
cat >> /etc/ntp.conf <<EOM

logfile /var/log/ntpd.log
EOM
rc-update add sshd default
rc-update add rsyslog default
rc-update add vixie-cron default
rc-update add ntp-client default
rc-update add ntpd default
cat > /etc/udev/rules.d/50-eth_tso.rules <<EOM
ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth0", RUN+="/sbin/ethtool -K eth0 tso off"
EOM

# Configuring the Bootloader
cat > /boot/grub/menu.lst <<EOM
default 0
timeout 3
serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
terminal --timeout=10 serial console
title=Gentoo Linux
    root (hd0,0)
    kernel /boot/kernel-$(cat /kernel-version.txt) root=/dev/vda3 console=tty0 console=ttyS0,115200n8r
EOM
grep -v rootfs /proc/mounts > /etc/mtab

# bug 259613
echo "(hd0)   /dev/vda" >> /boot/grub/device.map
grub-install --no-floppy /dev/vda

# Post install
rm -f /kernel-version.txt
sed -i \
    -e "s|^c2:2345|#c2:2345|" \
    -e "s|^c3:2345|#c3:2345|" \
    -e "s|^c4:2345|#c4:2345|" \
    -e "s|^c5:2345|#c5:2345|" \
    -e "s|^c6:2345|#c6:2345|" \
    -e 's_^#s0:12345:respawn:/sbin/agetty 115200 ttyS0 vt100_s0:12345:respawn:/sbin/agetty -h 115200 ttyS0 vt100_g' \
    /etc/inittab

exit
