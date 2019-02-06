# Scripts

## Raspberrypi nspawn setup

### build raspi ARCH image that can be copied to sd card
sudo ./prepare_raspi_image_arch64.sh rpi3bp.img

### boot the image with nspawn on your host
sudo ./nspawn_boot.sh rpi3bp.img

### terminate the machine
sudo machinectl terminate raspiroot
