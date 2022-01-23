# AALIS -- Advanced ArchLinux Install Script

`AALIS IN ARCHLAND`

Pronounced as "Alice". This script helps me personally install ArchLinux along with most of the packages I use/need for my systems. This script makes several assumptions, based on my needs and on what hardware I have on my system (such as use of swapfile, partition path names, what kernel packages are installed). This can be useful for other systems but be aware that your system might require different packages (especially for things like the bootloader); you are free to modify the script to fit your system as needed!

## What it does
- Automatically configures ArchLinux in chroot environment, as per the [Installation Guide](https://wiki.archlinux.org/title/installation_guide)
- Installs various packages for basic terminal use and has optional DE install optional.
- Adds parameters needed for LUKS, BTRFS, and Swapfile+ZRAM
- Sets up XDG folder specifications for users and environment variables
- Installs and Configures shells like Bash, ZSH, Fish; aswell as terminal editors like VIM, Neovim, Nano, and Emacs 
- Can install aditional packages for laptops, like TLP and Wacom touchscreen support
- Installs Libvirt and Virt manager, as well as configures all users for libvirt
- Configures sudoers (adds all user accounts to wheel group)
- Saves script output in multiple log files under the logs directory
- Installs yay AUR helper and AUR packages
- Installs and Configures Systemd-boot and Grub
- Sets up partitions for BIOS and UEFI mode
- The script doesn't *explicitly* check if it has ran twice, but any changes that were made will be undone as the script will automatically unmount the disks and wipe it clean.
- Detect and load in all UUIDs necessary for storage configuration
- Colorful output!!
- Sets up ssh-agent as a systemd service in order for ssh-agent to start up by default.
- (NEW IN v3) Can now install user specified packages via `user_pkglist.txt`! See my own list, [user_pkglist.txt.example](premade-configs/packages/user_pkglist.txt.example)
- Dracula theme can now be enabled under KDE

## What it doesn't do
- Automatically add kernel parameters for LUKS, BTRFS, and SWAP for mkinicpio, it just echoes the names of the parameters into the mkinitcpio file
- Configure keyboard layout, languages, and timezones other than those specified in the script itself (US English, QWERTY layout for 104 keys). The script must be modified in order to account for those.
- Make DE use custom theme that don't look at the environment variables. The theme I use, [Dracula](https://draculatheme.com/) is installed; but I haven't figured out away to automatically tell the DE to use the theme. (Now possible in KDE but not in the others)

## How to run this script
- Type the following commands in the prompt:
```
pacman -S git
git clone https://gitlab.com/NovaViper/aalis
cd aalis
./aalis.sh
```

## How to Specify User Packages to Install
- Before starting the script, create a file called user_pkglist.txt under premade-configs/packages (or see the example, [user_pkglist.txt.example](premade-configs/packages/user_pkglist.txt.example))
- Add package names to the file, each package on a new line
- Save the file within the script directory, then run the main script!

## Changelog
See [CHANGELOG](CHANGELOG) to see how the script has changed over time

## Plans?
I have alot more planned for the script! See [PLANNED](PLANNED.md) to see what other things I have in store for the script.

## CREDIT
- Version 2.0 of the script is based on Chris Titus' [ArchTitus installer](https://github.com/ChrisTitusTech/ArchTitus), which allowed for AUR packages to be possible to be installed as well as various new functionality.
- StackOverflow and Unix Stack Exchange Communities for helping me figured out major parts of the code
