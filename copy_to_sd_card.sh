#!/bin/bash

image_file=$1

# check 'ls /dev' to find the appropriate device handle for your sd card
sdcard_device=$2

#maybe add a sync option conv=sync status=progress
dd if=$image_file of=$sdcard_device bs=4k conv=sync status=progress

sync
