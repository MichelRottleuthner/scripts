#!/bin/bash

usage_exit() {
  echo -e "This script prepares an ARCH (aarch64) image for the raspi 3b+\n" \
          "that can be directly dd copied to an sdcard." \
  echo "Usage: $0 -i image_file" 1>&2
  exit 1
}

while getopts i: option
do
case "${option}"
in
i) sdcard_image=${OPTARG};;
esac
done

if [ -z $sdcard_image ]; then
  echo "no image file specified! use -i somefile.img"
  usage_exit
fi

arch_archive_url=http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-3-latest.tar.gz
#arch_archive_url=http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz

raspi_boot_folder=raspi_boot
raspi_root_folder=raspi_root

sfdisk_config_file=raspi_sdcard.sfdisk

arch_archive_file=$(basename -a $arch_archive_url)

#download archive file if not already present
[ -f $arch_archive_file ] || curl -L -o $arch_archive_file $arch_archive_url

fallocate -l 4G $sdcard_image
# maybe fall back to something like this if fallocate isn't working:
#dd if=/dev/zero of=$sdcard_image bs=4k iflag=fullblock,count_bytes count=8G

sfdisk $sdcard_image < $sfdisk_config_file
sync

loopback_dev=$(losetup -f)
losetup --partscan $loopback_dev $sdcard_image

#make sure the partition table is read again
partprobe

boot_parition=$(fdisk -l $loopback_dev | grep "^$loopback_dev" | sed "1q;d" | cut -d' ' -f1)
root_parition=$(fdisk -l $loopback_dev | grep "^$loopback_dev" | sed "2q;d" | cut -d' ' -f1)

mkfs.vfat $boot_parition
mkfs.ext4 $root_parition
sync

rm -rf $raspi_boot_folder $raspi_root_folder
mkdir $raspi_boot_folder
mkdir $raspi_root_folder
mount $boot_parition $raspi_boot_folder
mount $root_parition $raspi_root_folder

bsdtar -xpf $arch_archive_file -C raspi_root
sync

mv $raspi_root_folder/boot/* $raspi_boot_folder

umount $raspi_boot_folder $raspi_root_folder

rmdir $raspi_boot_folder $raspi_root_folder

losetup -d $loopback_dev
