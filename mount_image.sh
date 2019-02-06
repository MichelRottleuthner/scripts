#!/bin/bash
sdcard_image=$1
raspi_boot_folder=$2
raspi_root_folder=$3

loopback_dev=$(losetup -f)
losetup --partscan $loopback_dev $sdcard_image

boot_parition=$(fdisk -l $loopback_dev | grep "^$loopback_dev" | sed "1q;d" | cut -d' ' -f1)
root_parition=$(fdisk -l $loopback_dev | grep "^$loopback_dev" | sed "2q;d" | cut -d' ' -f1)

mount $boot_parition $raspi_boot_folder
mount $root_parition $raspi_root_folder

echo $loopback_dev
