#!/bin/bash

usage_exit() {
  echo -e "This script can be used to boot a raspberrypi image inside a" \
          "systemd-nspawn container.\n" \
          "'-m shell' boots the container to an interactive shell\n" \
          "'-m setup' executes the setup.sh script provided next to this script"
  echo "Usage: $0 -i image_file [-m {shell|setup}]" 1>&2
  exit 1
}

sdcard_image=$1

# ensure paths are absolute for systemd stuff
raspi_boot_folder=$(realpath raspi_boot)
raspi_root_folder=$(realpath raspi_root)

nspawn_machine_name=rpicontainertmp

setup_script=$(realpath ./setup.sh)

rm -rf $raspi_boot_folder $raspi_root_folder
mkdir $raspi_boot_folder
mkdir $raspi_root_folder

# by default invoke a shell to work inside the container
# alternatively provide
nspawn_invocation=shell

while getopts i:m: option
do
case "${option}"
in
i) sdcard_image=${OPTARG};;
m) nspawn_invocation=${OPTARG};;
esac
done

if [ -z $sdcard_image ]; then
  echo "no image file specified! use -i somefile.img"
  usage_exit
fi

if ! [ $nspawn_invocation == "shell" -o \
       $nspawn_invocation == "setup" ]; then
  echo "invocation mode invalid! usage -m {shell|setup}"
  usage_exit
fi

loopback_dev=$(sudo ./mount_image.sh $sdcard_image $raspi_boot_folder $raspi_root_folder)

# start container directly with systemd-nspawn but put it to background
# this way we don't need a unit file for
sudo systemd-nspawn --boot \
                    --bind /usr/bin/qemu-aarch64-static \
                    --bind /usr/bin/qemu-arm-static \
                    --bind $raspi_boot_folder:/boot \
                    --bind-ro $setup_script \
                    --directory $raspi_root_folder \
                    --resolv-conf=bind-host \
                    --machine=$nspawn_machine_name > /dev/null 2>&1 &


# wait a bit so machinectl can see the container
sleep 5

if [ $nspawn_invocation == "shell" ]; then
  #open interactive shell
  sudo machinectl shell --machine=$nspawn_machine_name --quiet
fi

if [ $nspawn_invocation == "setup" ]; then
  #execute default setup script within the container
  sudo systemd-run --machine=$nspawn_machine_name --pty --quiet /bin/bash $setup_script
fi

echo "shutting down the container..."
sudo machinectl poweroff $nspawn_machine_name

# wait for the shut down process to finish
terminated=0
while [ $terminated -eq 0 ]
do
    printf "."
    sleep 1
    machinectl show $nspawn_machine_name > /dev/null 2>&1
    terminated=$?
    # maybe add something like the following incase this takes too long?
    #sudo machinectl terminate $nspawn_machine_name
done

echo "container shut down complete"

sync
sudo umount $raspi_boot_folder $raspi_root_folder

sudo losetup -d $loopback_dev

rmdir $raspi_boot_folder $raspi_root_folder

echo "The image is now ready to be copied to the sdcard"
