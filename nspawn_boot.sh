#!/bin/bash

sdcard_image=$1

raspi_boot_folder=raspi_boot
raspi_root_folder=raspi_root

rm -rf $raspi_boot_folder $raspi_root_folder
mkdir $raspi_boot_folder
mkdir $raspi_root_folder

loopback_dev=$(sudo ./mount_image.sh $sdcard_image $raspi_boot_folder $raspi_root_folder)

sudo systemd-nspawn -b --bind /usr/bin/qemu-aarch64-static \
                    -D $raspi_root_folder

sudo umount $raspi_boot_folder $raspi_root_folder

sudo losetup -d $loopback_dev
