#!/usr/bin/env bash

# Variable declarations
use_crypt=""
use_swap=""
use_btrfs=""
is_laptop=""
is_vm=""
boot_mode=""
root_drive_uuid=""
boot_drive_name=""
bootloader=""
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}') # Get the current usable RAM of the system in KB
RAM_MB=$(expr $RAM_KB / 1024)
RAM_GB=$(expr $RAM_MB / 1024)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # Locate and save the script's current base directory

#Enable logging!
mkdir ${SCRIPT_DIR}/logs
touch ${SCRIPT_DIR}/logs/preinstall.log
exec &> >(tee ${SCRIPT_DIR}/logs/preinstall.log)

# Preflight check ensures that the script_funcs file (which holds all primary functions for the script)
# is present. This file under any circumstance SHOULD NEVER be missing or really bad things will happen.
echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2

banner ${LIGHT_PURPLE} "Configuring Pacman"
sed -i 's/^#Color/Color/' /etc/pacman.conf # Enable colored output
sed -i 's/^#Para/Para/' /etc/pacman.conf # Enable Parallel downloading for faster installation


banner ${LIGHT_PURPLE} "Starting Preinstallation Phase"
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then output ${LIGHT_BLUE} "Removing old sysconfig.conf"; rm ${SCRIPT_DIR}/sysconfig.conf; fi # Clean up old run

if [[ "yes" == $(askYesNo "Are you installing ArchLinux on a laptop?") ]]; then is_laptop="yes"; fi

if [[ "yes" == $(askYesNo "Are you installing ArchLinux on a VM?") ]]; then is_vm="yes"; fi

if [[ "yes" == $(askYesNo "Do you want to use SWAP?") ]]; then use_swap="yes"; fi

if [[ "yes" == $(askYesNo "Do you want to use LUKS disk encryption?") ]]; then use_crypt="yes"; fi


while true; do
	read -p "$(output ${YELLOW} "What bootloader do you want to use? [G]rub, or [S]ystem-Boot?: ")" boot
	case $boot in
		S | s)
			if [ ! -d /sys/firmware/efi ]; then
				output ${LIGHT_RED} "Systemd-Boot only supports UEFI firmware! Please select something else!"
				continue
			fi

			output ${YELLOW} "Ok, I will make sure to configure the system for systemd-boot"
			bootloader="systemd"
			break;;
		G | g)
			output ${YELLOW} "Ok, I will make sure to configure the system for GRUB"
			bootloader="grub"
			break;;
		*) output ${LIGHT_RED} "Invalid input" ;;
	esac
done

while true; do
	banner ${LIGHT_PURPLE} "Select a disk you wish to format"
	lsblk
	echo "Please enter disk to work on: (example /dev/sda)"
	read DISK
	if [[ ! "$DISK" = "" ]]; then
		output ${LIGHT_RED} "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK!"
		if [[ "no" == $(askYesNo ${LIGHT_RED} "Are you sure you want to continue?") ]]; then
			output ${LIGHT_RED} "Ok.. going to ask again"
			clear
		else
			output ${LIGHT_GREEN} "Ok, lets get started!"
			sleep 1
			clear
			break;
		fi
	else
		output ${LIGHT_RED} "This cannot be blank! Please try again!"
	fi
done

banner ${LIGHT_PURPLE} "Formatting disk, ${DISK}..."
if grep -qs '/mnt' /proc/mounts; then
	output ${YELLOW} "Attempting to unmount"
	umount /mnt/boot/efi
	umount /mnt/boot
	umount /mnt/* -A -f
	umount /mnt -A -f
	if [[ "$use_crypt" = "yes"  ]]; then cryptsetup close cryptroot; fi
fi

sgdisk -Z ${DISK} # Destory everything on disk
sgdisk -a 2048 -o ${DISK} # New gpt partition table with 2048 alignment

# Create partitions
if [ -d /sys/firmware/efi ]; then
	boot_mode="uefi"
	output ${YELLOW} "Detected UEFI System, Creating UEFI Partitions..."
	if [[ "$bootloader" = "grub" ]]; then
		output ${YELLOW} "Setting up filesystems for Grub..."
		sgdisk -n 1::+250M --typecode=1:bc13c2ff-59e6-4262-a352-b275fd6f7172 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (Linux System Partition)
		sgdisk -n 2::+100M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
		sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
	elif [[ "$bootloader" = "systemd" ]]; then
		output ${YELLOW} "Setting up filesystems for Systemd-boot..."
		sgdisk -n 1::+512M --typecode=1:ef00 ${DISK} # partition 1 (UEFI Boot Partition)
		sgdisk -n 2::-0 --typecode=2:8300 ${DISK} # partition 2 (Root), default start, remaining
	fi
else
	boot_mode="bios"
	output ${YELLOW} "Detected BIOS System, Creating BIOS Partitions..."
	sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
	sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
	sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
	sgdisk -A 1:set:2 ${DISK}
fi

makeFilesystems ${DISK}


output ${LIGHT_BLUE} "Lets confirm if everything is correct!"
output ${YELLOW} "Checking if there are any mounts"
if ! grep -qs '/mnt' /proc/mounts; then
	output ${LIGHT_RED} "Drive is not mounted; cannot continue!"
	exit 1
fi

lsblk
if [[ "yes" = $(askYesNo "Does everything look correct?") ]]; then
	output ${LIGHT_GREEN} "Ok, moving on!"
else
	output ${LIGHT_RED} "Something must've gone wrong, cannot continue!"
	exit 1
fi

banner ${LIGHT_PURPLE} "Arch Install on Main Drive"
pacstrap /mnt --noconfirm --needed base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# Add swap to fstab, so it KEEPS working after installation. Added lower priority for zram
if [[ "$use_swap" = "yes"  ]]; then echo "/swap/swapfile    none    swap    defaults,pri=10     0   0" >> /mnt/etc/fstab; fi

output ${LIGHT_BLUE} "Lets do one final check to make sure your mounts are correct! I will display the fstab in 5 seconds."
sleep 5
cat /mnt/etc/fstab
if [[ "yes" = $(askYesNo "Does your fstab look correct?") ]]; then
	output ${LIGHT_GREEN} "Ok, moving on!"
else
	output ${LIGHT_RED} "Something must've gone wrong, cannot continue!"
	exit 1
fi

output ${LIGHT_BLUE} "Saving Parameters for next step"
touch ${SCRIPT_DIR}/sysconfig.conf
cat <<-EOF >> ${SCRIPT_DIR}/sysconfig.conf
use_swap=$use_swap
use_btrfs=$use_btrfs
use_crypt=$use_crypt
is_laptop=$is_laptop
is_vm=$is_vm
boot_mode=$boot_mode
root_drive_uuid=$root_drive_uuid
boot_drive_name=$boot_drive_name
bootloader=$bootloader
EOF

banner ${LIGHT_GREEN} "SYSTEM READY FOR 1-setup"
sleep 3
clear
