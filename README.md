# Scripts
Some helper scripts.

## Fetch and build ARCH (aarch46) raspi 3b+ image that can be copied to sd card
`sudo ./prepare_raspi_image_arch64.sh -i rpi3bp.img`

## Raspberrypi nspawn setup

### boot to an interactive shell, running the image within an nspawn container
`sudo ./nspawn_boot.sh -i rpi3bp.img -m shell`

### boot the container and execute the provided default setup.sh script
`sudo ./nspawn_boot.sh -i rpi3bp.img -m setup`

### terminate the machine from another session
`sudo machinectl terminate rpicontainertmp`

## copy the image to an actual sdcard
`sudo ./copy_to_sd_card.sh rpi3bp.img /dev/mmcblk0`
