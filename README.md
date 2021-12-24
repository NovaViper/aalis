# AALIS -- Advanced ArchLinux Install Script

`AALIS IN ARCHLAND`

Pronouced as "Alice". This script helps me personally install ArchLinux along with most of the packages I use/need for my systems. This script makes several assumptions, based on my needs and on what hardware I have on my system (such as use of swapfile, partition path names, what kernel packages are installed). This can be useful for other systems but be aware that your system might require different packages (especially for things like the bootloader); you are free to modify the script to fit your system as needed!

## What it does
- Automatically configures ArchLinux in chroot environment, as per the [Installation Guide](https://wiki.archlinux.org/title/installation_guide)
- Installs various packages for basic terminal use (i.e. neovim) and has optional DE install optional.
- Adds parameters needed for LUKS, BTRFS, and Swapfile+ZRAM
- Sets up XDG folder specifications for users and environment variables
- Installs and Configurations ZSH, Neovim and Pfetch
- Can install aditional packages for laptops, like TLP and Wacom touchscreen support
- Installs Libvirt and Virt manager, as well as configures all users for libvirt
- Configures sudoers (adds all user accounts to wheel group)
- Saves script output in multiple log files under the logs directory
- Installs yay AUR helper and AUR packages
- Installs and Configures Systemd-boot and Grub
- Sets up partitions for BIOS and UEFI mode
- The script doesn't *explictly* check if it has ran twice, but any changes that were made will be undone as the script will automatically unmount the disks and wipe it clean.
- Detect and load in all UUIDs necessary for storage configuration
- Colorful output!!
- Sets up ssh-agent as a systemd service in order for ssh-agent to start up by default.

## What it doesn't do
- Automatically add kernel parameters for LUKS, BTRFS, and SWAP for mkinicpio, it just echoes the names of the paramters into the mkinitcpio file
- Configure keyboard layout, langauges, and timezones other than those specified in the script itself (US English, QWERTY layout for 104 keys). The script must be modified in order to account for those.
- Make DE use custom theme that don't look at the environment variables. The theme I use, [Dracula](https://draculatheme.com/) is installed; but I haven't figured out away to automatically tell the DE to use the theme.

## How to run this script
- Type the following commands in the prompt:
```
pacman -S git
git clone https://gitlab.com/NovaViper/aalis
cd aalis
./aalis.sh
```

## CREDIT
- The latest of the script is based on Chris Titus' [ArchTitus installer](https://github.com/ChrisTitusTech/ArchTitus), which allowed for AUR packages to be possible to be installed as well as various new functionality.
