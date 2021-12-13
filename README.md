# AALIS -- Advanced ArchLinux Install Script

This script helps me personally install ArchLinux along with most of the packages I use/need for my systems. This script makes several assumptions, based on my needs and on what hardware I have on my system (such as use of swapfile, partition path names what kernel packages are installed). This can be useful for other systems but be aware that your system might require different packages (especially for things like the bootloader); you are free to modify the script to fit your system as needed!

## What it does
- Automatically configures ArchLinux in chroot environment, as per the [Installation Guide](https://wiki.archlinux.org/title/installation_guide)
- Installs various packages for basic terminal use (i.e. neovim) and has optional DE install optional.
- Adds parameters needed for LUKS, BTRFS, LVM and Swapfile
- Sets up XDG folder specifications for users and environment variables
- Installs and Configurations ZSH, Neovim and Neofetch with basic and advanced configurations (just change the remove the .pending tag off the file names for the advanced configurations)
- Can install aditional packages for laptops, like TLP and Wacom touchscreen support
- Installs Libvirt and Virt manager, as well as configures all users for libvirt
- Configures sudoers (adds all user accounts to wheel group)
- Saves script output in a log.txt file
- Installs yay AUR helper
- Installs and Configures Systemd-boot and Grub
- Installs AUR packages (via the yay-packages.sh file) and configures some packages (working on getting things like enabling user systemd scripts)

## What it doesn't do
- Automatically add kernel parameters for LUKS, BTRFS LVM, and SWAP for mkinicpio, it just echoes the names of the paramters into the mkinitcpio file
- Locate the UUID for the storage device itself, it can get the UUID for the partitions however (this is crucial particuaraly for LUKS as it **requires** the UUID of the *storage device*, not the parition). You must manually locate the storage device's UUID via the `blkid -o list` command. See [Configuring Bootloader for LUKS](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_the_boot_loader).
- Install AUR packages, those must be installed after the system is booted and logged into the *user* account.
- Setup ZSH and Neovim WITH plugins, it does provide a basic config for both programs, but you must install Zplug and NVimPlug (which are only available as AURs). After you install Zplug and NVimPlug, you may remove the .pending tag off the end of the file name (which will overwrite the minimal configurations).
- Configure keyboard layout, other langauges, and other timezones. The script must be modified in order to account for those
- Check if the script was ran once already, **This is EXTREMELY important as the script will rerun all of the commands again, which will break things!**
- Support anything  that isn't swapfiles.
- Configure partitions, you should have already done this prior to getting into chroot!
- Enable Emacs client systemd user script, since Emacs systemd requires you to run it on a user account, the script obviously cannot enable it in this phase, you will have to enable it after you reboot.
- Configure DE theme. The theme I use, (Dracula)[https://draculatheme.com/] is installed via the yay-packages script, but I haven't figured out away to automatically tell the DE to use the theme (other than using the environment variables).

## How to run this script
- Simply clone the entire repo onto your computer using `git clone https://gitlab.com/NovaViper/archlinux-install-script/`
- Run `chmod+x ./basic-efi.sh` to make the script executable.
- Then finally, run `./basic-efi.sh` to run the script.
