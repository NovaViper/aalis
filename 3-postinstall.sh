#!/usr/bin/env bash

# Variable Declarations
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # Locate and save the script's current base directory

#Enable logging!
touch ${SCRIPT_DIR}/logs/postinstall.log
exec &> >(tee ${SCRIPT_DIR}/logs/postinstall.log)

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then source ${SCRIPT_DIR}/sysconfig.conf; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/sysconfig.conf!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/sysconfig.conf, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2

banner ${LIGHT_PURPLE} "FINAL SETUP AND CONFIGURATION"
if [[ "$bootloader" = "systemd" ]]; then
	banner ${LIGHT_PURPLE} "Installing Systemd-Boot"
	bootctl install
	output ${YELLOW} "Creating Boot Configurations"
	microcode_hook=""
	if [ "$microcode_type" = "amd" ]; then microcode_hook="/amd-ucode.img"; fi
	if [ "$microcode_type" = "intel" ]; then microcode_hook="/intel-ucode.img"; fi
	sed -i '/timeout/s/^#//g' /boot/loader/loader.conf
	sed -i '/default/s/^/#/g' /boot/loader/loader.conf
	echo "default arch-*.conf" >> /boot/loader/loader.conf
	touch /boot/loader/entries/arch-latest.conf
	if [[ ! -z "$microcode_type" ]]; then
		cat <<-EOF >> /boot/loader/entries/arch-latest.conf
		title  ArchLinux
		linux   /vmlinuz-linux
		initrd  ${microcode_hook}
		initrd  /initramfs-linux.img
		EOF
	else
		cat <<-EOF >> /boot/loader/entries/arch-latest.conf
		title  ArchLinux
		linux   /vmlinuz-linux
		initrd  /initramfs-linux.img
		EOF
	fi
	root_uuid="$(findmnt -no UUID -T /)"
	root_flags="root=UUID=${root_uuid}"
	swap_flags=""

	if [ "$use_crypt" = "yes" ]; then
		output ${YELLOW} "Configuring bootloader for disks encryption"
		root_flags="cryptdevice=UUID=${root_drive_uuid}:cryptroot ${root_flags}"
	fi

	if [ "$use_btrfs" = "yes" ]; then
		output ${YELLOW} "Getting Root Subvolume Information..."
		getSubvolInfo
		root_flags="${root_flags} rootflags=subvolid=${rootsubvol_id},subvol=${rootsubvol_name}"
	fi

	if [ "$use_swap" = "yes" ]; then
		output ${YELLOW} "Getting Swap file UUID"
		swap_uuid="$(findmnt -no UUID -T /swap/swapfile)"

		if [ "$use_btrfs" = "yes" ]; then
			output ${YELLOW} "Calculating Swap offset for swapfile subvolume..."
			curl https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c -o ${SCRIPT_DIR}/btrfs_map_physical.c
			gcc -O2 -o ${SCRIPT_DIR}/btrfs_map_physical ${SCRIPT_DIR}/btrfs_map_physical.c
			offset=`${SCRIPT_DIR}/btrfs_map_physical /swap/swapfile`
			offset_arr=(`echo ${offset}`)
			offset_pagesize=(`getconf PAGESIZE`)
			swap_offset=$(( offset_arr[25] / offset_pagesize ))
		else
			output ${YELLOW} "Calculating Swap offset for swap file..."
			swap_offset="$(filefrag -v /swap/swapfile | awk '{ if($1=="0:"){print substr($4, 1, length($4)-2)} }')"
		fi

		swap_flags="resume=UUID=${swap_uuid} resume_offset=${swap_offset}"
	fi

	output ${YELLOW} "Finishing creating configuration file for Systemd-Boot..."
	echo "options rw ${root_flags} ${swap_flags}" >> /boot/loader/entries/arch-latest.conf
elif [[ "$bootloader" = "grub" ]]; then
	banner ${LIGHT_PURPLE} "Installing GRUB"
	installPac "grub efibootmgr"

	if [[ "$boot_mode" = "uefi" ]]; then
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck ${boot_drive_name}
	else
		grub-install --boot-directory=/boot --bootloader-id=ArchLinux --recheck ${boot_drive_name}
	fi

	output ${YELLOW} "Creating Boot Configurations"
	root_uuid="$(findmnt -no UUID -T /)"
	root_flags="root=UUID=${root_uuid}"
	swap_flags=""

	if [ "$use_crypt" = "yes" ]; then
		output ${YELLOW} "Configuring bootloader for disks encryption"
		root_flags="cryptdevice=UUID=${root_drive_uuid}:cryptroot ${root_flags}"
	fi

	if [ "$use_swap" = "yes" ]; then
		output ${YELLOW} "Getting Swap file UUID"
		swap_uuid="$(findmnt -no UUID -T /swap/swapfile)"

		if [ "$use_btrfs" = "yes" ]; then
			output ${YELLOW} "Calculating Swap offset for swapfile subvolume..."
			curl https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c -o ${SCRIPT_DIR}/btrfs_map_physical.c
			gcc -O2 -o ${SCRIPT_DIR}/btrfs_map_physical ${SCRIPT_DIR}/btrfs_map_physical.c
			offset=`${SCRIPT_DIR}/btrfs_map_physical /swap/swapfile`
			offset_arr=(`echo ${offset}`)
			offset_pagesize=(`getconf PAGESIZE`)
			swap_offset=$(( offset_arr[25] / offset_pagesize ))
		else
			output ${YELLOW} "Calculating Swap offset for swap file..."
			swap_offset="$(filefrag -v /swap/swapfile | awk '{ if($1=="0:"){print substr($4, 1, length($4)-2)} }')"
		fi

		swap_flags="resume=UUID=${swap_uuid} resume_offset=${swap_offset}"
	fi

	sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&'"${root_flags} ${swap_flags}"' /' /etc/default/grub
	output ${YELLOW} "Rebuilding GRUB..."
	grub-mkconfig -o /boot/grub/grub.cfg
fi

banner ${LIGHT_PURPLE} "Configuring mkinitcpio"
extra_hooks=""

if [ "$use_swap" = "yes" ]; then extra_hooks="resume ${extra_hooks}"; fi

if [ "$use_btrfs" = "yes" ]; then
	extra_hooks="btrfs ${extra_hooks}"
	sed -i '57s/.//' /etc/mkinitcpio.conf
fi

if [ "$use_crypt" = "yes" ]; then extra_hooks="encrypt ${extra_hooks}"; fi

if [[ "${extra_hooks}" ]]; then
	echo "#IMPORTANT Put these in HOOKS and delete this line after doing so: ${extra_hooks}" >> /etc/mkinitcpio.conf
	output ${LIGHT_BLUE} "IMPORTANT: Do not forget to put these parameters in the HOOKS section of /etc/mkinitcpio.conf! ${extra_hooks}"
	output ${LIGHT_BLUE} "The order of the hooks matter! The 'encrypt' hook goes before 'filesystems' , 'btrfs' goes after 'filesystems', and finally, 'resume' goes at the very end of the paramter list"
	output ${LIGHT_BLUE} "Be sure to run 'mkinitcpio -P' after adding the parameters! Your machine will not start properly if you skip doing this!"
	sleep 5
fi
