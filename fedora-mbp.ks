# Add rpm repo hosted on heroku https://github.com/mikeeq/mbp-fedora-kernel/releases
repo --name=fedora-mbp --baseurl=http://fedora-mbp-repo.herokuapp.com/

### Selinux in permissive mode
## enforcing=0 is not saved after installation in grub
bootloader --append=" enforcing=0"

### Disable gnome-initial-setup (not working)
eula --agreed
firstboot --disable
services --disabled="initial-setup-graphical"

### Install kernel from hosted rpm repo
%packages

git
gcc
gcc-c++
make
kernel-5.1.19-300.wifi.patch.fc30.x86_64
kernel-core-5.1.19-300.wifi.patch.fc30.x86_64
kernel-devel-5.1.19-300.wifi.patch.fc30.x86_64
kernel-modules-5.1.19-300.wifi.patch.fc30.x86_64
kernel-modules-extra-5.1.19-300.wifi.patch.fc30.x86_64

%end

### Remove other kernel versions than custom one
%post
KERNEL_VERSION=5.1.19-300.wifi.patch.fc30.x86_64

echo 'nameserver 8.8.8.8' > /etc/resolv.conf

rpm -e $(rpm -qa | grep kernel | grep -v headers | grep -v oops | grep -v wifi)

mkdir -p /opt/drivers
git clone https://github.com/MCMrARM/mbp2018-bridge-drv.git /opt/drivers/bce
git -C /opt/drivers/bce/ checkout 6574ac760ab47b1b28229f4a736edd9829188c3f
git clone --single-branch --branch mbp15 https://github.com/roadrunner2/macbook12-spi-driver.git /opt/drivers/touchbar
git -C /opt/drivers/touchbar/ checkout 3f01cdb5035c4bc6aceeb2e835ded30699b3c06e
PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin make -C /lib/modules/${KERNEL_VERSION}/build/ M=/opt/drivers/bce modules
PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin make -C /lib/modules/${KERNEL_VERSION}/build/ M=/opt/drivers/touchbar modules
cp -rf /opt/drivers/bce/*.ko /lib/modules/${KERNEL_VERSION}/extra/
cp -rf /opt/drivers/touchbar/*.ko /lib/modules/${KERNEL_VERSION}/extra/

echo -e 'hid-apple\nbcm5974\nsnd-seq\nbce' > /etc/modules-load.d/bce.conf
echo -e 'blacklist applesmc' > /etc/modprobe.d/blacklist.conf
echo -e 'add_drivers+="hid_apple snd-seq bce"' >> /etc/dracut.conf
echo -e 'force_drivers+="hid_apple snd-seq bce"' >> /etc/dracut.conf
/usr/sbin/depmod -a ${KERNEL_VERSION}
dracut -f /boot/initramfs-$KERNEL_VERSION.img $KERNEL_VERSION

/usr/sbin/useradd fedora
echo 'fedora' | /usr/bin/passwd fedora --stdin > /dev/null
/usr/sbin/usermod -aG wheel fedora > /dev/null

dnf remove -y kernel-headers
rm -rf /opt/drivers
rm -rf /etc/resolv.conf

echo -e 'exclude=kernel,kernel-core,kernel-devel,kernel-modules,kernel-modules-extra' >> /etc/dnf/dnf.conf
%end

### Remove efibootmgr part from bootloader installation step in anaconda
%post --nochroot

cp -rfv /tmp/kickstart_files/efi.py ${INSTALL_ROOT}/usr/lib64/python3.7/site-packages/pyanaconda/bootloader/efi.py
cp -rfv /tmp/kickstart_files/97-mbp-post-install.ks ${INSTALL_ROOT}/usr/share/anaconda/post-scripts/
cp -rfv /tmp/kickstart_files/98-mbp-regenerate-grub-cfg.ks ${INSTALL_ROOT}/usr/share/anaconda/post-scripts/
mkdir -p ${INSTALL_ROOT}/usr/share/alsa/cards/
cp -rfv /tmp/kickstart_files/AppleT2.conf ${INSTALL_ROOT}/usr/share/alsa/cards/AppleT2.conf

%end

%include fedora-live-workstation.ks
