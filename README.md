# ArchLinux Install Script

This script helps me personally install ArchLinux along with most of the packages I use/need for my systems.

## What it does
- Automatically configures ArchLinux in chroot environment, as per the [Installation Guide](https://wiki.archlinux.org/title/installation_guide)
- Installs various packages for basic terminal use (i.e. neovim) and has optional DE install optional
- Adds parameters needed for LUKS, BTRFS, LVM and Swapfile
- Sets up XDG folder specifications for users and environment variables
- Installs and Configurations ZSH
- Can install aditional packages for laptops, like TLP
- Installs Libvirt and Virt manager, as well as configures all users for libvirt
- Configures sudoers (adds all user accounts to wheel group)

## What it doesn't do
- Automatically add kernel parameters for LUKS and BTRFS, it just echoes the names of the paramters into the mkinitcpio file
- Locate the UUID for the storage device itself, it can get the UUID for the partitions however (this is crucial particuaraly for LUKS as it **requires** the UUID of the *storage device*, not the parition). You must manually locate the storage device's UUID via the `blkid -o list` command. See [Configuring Bootloader for LUKS](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_the_boot_loader).
- Install AUR packages, those must be installed after the system is booted and logged into the *user* account.
- Setup ZSH and Neovim WITH plugins, it does provide a basic config for both programs, but you must install Zplug and NVimPlug (which are only available as AURs)
- Configure keyboard layout, other langauges, and other timezones. The script must be modified in order to account for those
- Install Grub, it only installs Systemd-boot as that was the one that was easiest for me to install on my computer.
- Check if the script was ran once already, **This is EXTREMELY important as the script will rerun all of the commands again, which will break things!**

## How to run this script
- Simply clone the entire repo onto your computer using `git clone https://gitlab.com/NovaViper/archlinux-install-script/`
- Run `chmod+x ./basic-efi.sh` to make the script executable.
- Then finally, run `./basic-efi.sh` to run the script, if you want to save the output for debugging purposes, run `./basic-efi.sh > output.txt`.
