#!/usr/bin/env bash

#Enable logging!
touch ./logs.txt
exec &> >(tee ./logs.txt)

# Variable declarations
users=()
use_lvm=""
use_btrfs=""
use_crypt=""
use_bluetooth=""
use_swap=""
microcode=""

#Functions
function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
    y|yes) echo "yes" ;;
    *)     echo "no" ;;
    esac
}

addRootPass(){
    while true; do
        read -s -p "Create a new password for Root user: " password
        echo
        read -s -p "Enter the password (again): " password2
        echo
        if [[ "$password" = "" ]] && [[ "yes" == $(ask_yes_or_no "!!!!!!!THIS IS AN EXTREME SECURITY RISK AS ANYONE CAN AND WILL MODIFY YOUR SYSTEM AT ANY TIME!!!!!!! Do you accept the consequences??")  ]]; then
            if [[ "yes" == $(ask_yes_or_no "Are you REALLY sure? !!!!!IT IS HIGHLY RECOMMENDED NOT TO DO THIS FOR THE ROOT USER!!!!!") ]]; then break; fi
        fi
        [ "$password" = "$password2" ] && break
        echo "Please try again"
    done

    echo "Adding password for root user..."
    echo "root:$password" | chpasswd
}

addUserPass(){
    while true; do
        read -p "Please enter a name for the new user: " username
        if [[ ! "${users[*]}" =~ "${username}" ]]; then
            read -s -p "Create a new password for $username: " password
            echo
            read -s -p "Enter the password (again): " password2
            echo
            if [[ "$password" = "" ]] && [[ "yes" == $(ask_yes_or_no "!!!!!This is a security risk and allows anyone to get into your machine!!!!!! Do you accept the consequences?")  ]]; then
                if [[ "yes" == $(ask_yes_or_no "Are you REALLY sure?") ]]; then break; fi
            fi
            [ "$password" = "$password2" ] && break
            echo "Please try again"
        elif [[ "${username}" =~ "root" ]]; then
            echo "You cannot create a user with the name root, as it is reserved for the admin account. Please try a different username."
        else
            echo "You already entered this username, please enter a new username"
        fi
    done

    echo "Creating $username..."
    useradd -m -G wheel $username
    users+=("$username")
    #echo "DEBUG: ${users[@]}"
    echo "$username:$password" | chpasswd
}




################ START OF SCRIPT ##############
echo "Enabling Multilib library and configuring Pacman"
sed -i '33s/.//' /etc/pacman.conf
sed -i '93s/.//' /etc/pacman.conf
sed -i '94s/.//' /etc/pacman.conf
pacman -Syy
echo "Configuring NTP, language and hostname information"
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
systemctl enable systemd-timesyncd
hwclock --systohc
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
read -p 'Hostname: ' hostname
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "127.0.0.1 $hostname" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts

#Ask for root password
addRootPass

echo "========= Installing Base packages and wireless modules ========="
pacman -S --noconfirm --needed base base-devel linux linux-firmware git gnupg zsh networkmanager network-manager-applet networkmanager-openvpn dialog wpa_supplicant wireless_tools netctl inetutils openssh openvpn openssh-askpass
pacman -U yay-bin-11.0.2-1-x86_64.pkg.tar.zst
systemctl enable NetworkManager
systemctl enable sshd


echo "========= Installing Filesystem packages ========="
pacman -S --noconfirm --needed ntfs-3g nfs-utils e2fsprogs smartmontools btrfs-progs gvfs gvfs-smb unzip unrar


echo "========= Installing Extra packages ========= "
pacman -S git neovim emacs yadm neofetch


echo "========= Installing User directories and updating ========="
pacman -S --noconfirm xdg-user-dirs xdg-utils
xdg-user-dirs-update
echo "Configuring environment variables"
echo >> /etc/profile
echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> /etc/profile
echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> /etc/profile
echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> /etc/profile
echo 'export XDG_STATE_HOME="$HOME/.local/state"' >> /etc/profile

echo "QT_STYLE_OVERRIDE=kvantum" >> /etc/environment
echo "GTK_THEME='Ant-Dracula'" >> /etc/environment

echo "========= Configuring ZSH ========="
#Place zsh files in /etc/zsh folder for system-wide use
cp ./zshenv /etc/zsh/zshenv

#Place zshrc files in skel folder so users can get them
mkdir /etc/skel/.config
mkdir /etc/skel/.config/zsh
cp ./zshrc /etc/skel/.config/zsh/.zshrc.pending
cp ./zshrc_min /etc/skel/.config/zsh/.zshrc
echo "IMPORTANT: In order to use zshrc configuration, don't forget to install Zplug! It will remain as user_home/.config/zsh/.zshrc.pending"

echo "========= Configuring Neovim ========="
mkdir /etc/skel/.config/nvim
cp ./init.vim /etc/skel/.config/nvim/init.vim.pending
cp ./init_min.vim /etc/skel/.config/nvim/init.vim
cp ./plugins.vim /etc/skel/.config/nvim/plugins.vim
echo "IMPORTANT: In order to use init.vim configuration, don't forget to install Nvim Plug! It will remain as /etc/nvim/init.vim.pending and HOME/.config/nvim/init.vim.pending"


echo "========= Configuring Neofetch ========="
mkdir /etc/skel/.config/neofetch
cp ./config.conf /etc/skel/.config/neofetch/config.conf

echo "========= Configuring sudoers ========="
sudo sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

#Additional User Prompt
while [[ "yes" == $(ask_yes_or_no "Would you like to add any additional users?") ]]; do addUserPass; done

#Configure ZSH for additional users
if [[ "${users[@]}" ]]; then
    echo "====== Configuring additional users for zsh ======"
    echo
    for i in "${users[@]}"; do
        echo "Changing shell for $i to zsh"
        usermod -s /bin/zsh $i
    done
fi


echo "========= Installing ALSA and Audio protocols ========="
pacman -S --noconfirm alsa-utils pulseaudio gst-libav gst-plugins-ugly gst-plugins-bad pulseaudio-alsa pipewire-alsa


if [[ "yes" == $(ask_yes_or_no "Would you like to download and enable Bluetooth?") ]]; then
    echo "========= Installing Bluetooth ========="
    use_bluetooth="yes"
    pacman -S --noconfirm bluez bluez-utils
    systemctl enable bluetooth pulseaudio-bluetooth
fi


if [[ "yes" == $(ask_yes_or_no "Would you like to install HP Printer Modules?") ]]; then
    echo "========= Installing HP modules ========="
    pacman -S --noconfirm cups cups-filters hplip
    systemctl enable cups
fi


#Installer based on instructions from: https://boseji.com/posts/manjaro-kvm-virtmanager/
if [[ "yes" == $(ask_yes_or_no "Would you like to install Virt-Manager?") ]]; then
    echo "========= Installing Virt-Manager, Qemu and other required packages ========="
    echo "Note: The package iptables-nft will conflict with iptables, please allow iptables-nft to install in order to use Virt-Manager's virutal ethernet feature."
    sleep 5
    pacman -S qemu libvirt iptables-nft dnsmasq virt-manager virt-viewer bridge-utils dmidecode edk2-ovmf
    systemctl enable libvirtd
    echo "====== Configuring KVM ======"
    sed -i '/unix_sock_group/s/^#//g' /etc/libvirt/libvirtd.conf
    sed -i '/unix_sock_rw_perms/s/^#//g' /etc/libvirt/libvirtd.conf
    virsh net-autostart default

    if [[ "${users[@]}" ]]; then
        echo "====== Configuring additional users for libvirt ======"
        echo
        for i in "${users[@]}"; do
            echo "Adding $i to libvirt group"
            usermod -a -G libvirt $i
        done
    fi
fi


if [[ "yes" == $(ask_yes_or_no "Are you installing on a laptop?") ]]; then
    echo "========= Installing TLP and other battery management tools ========="
    pacman -S --noconfirm acpi acpi_call tlp tlpui
    systemctl enable tlp

    if [[ "yes" == $(ask_yes_or_no "Does your laptop have touchscreen capability?")  ]]; then
        echo "========= Installing Wacom settings ========="
        pacman -S --noconfirm libwacom xf86-input-wacom
    fi
fi


if [[ "yes" == $(ask_yes_or_no "Did you use BTRFS for the file system?") ]]; then use_btrfs="yes"; fi


if [[ "yes" == $(ask_yes_or_no "Did you use LVM for the file system?") ]]; then
    echo "========= Installing LVM related packages ========="
    use_lvm="yes"
    pacman -S --noconfirm lvm2
fi


if [[ "yes" == $(ask_yes_or_no "Did you use LUKS disk encryption?") ]]; then use_crypt="yes"; fi


if [[ "yes" == $(ask_yes_or_no "Did you make a swap partition?") ]]; then use_swap="yes"; fi

#Processor Microcode Installer
while true; do
    read -p "What brand is your processor? [I]ntel or [A]MD?: " processor
    case $processor in
    I | i)
        echo "========= Installing Intel Microcode ========="
        microcode="intel"
        pacman -S --noconfirm intel-ucode
        break;;
    A | a)
        echo "========= Installing AMD Microcode ========="
        microcode="amd"
        pacman -S --noconfirm amd-ucode
        break;;
    *) echo "Invalid input";;
    esac
done


#Graphics Installer
while true; do
    read -p "What brand is your graphics? [I]ntel, [A]MD or [N]vidia?: " graphics
    case $graphics in
    I | i)
        echo "========= Installing Intel Graphics ========="
        pacman -S --noconfirm xf86-video-intel mesa vulkan-driver vulkan-intel lib32-mesa lib32-vulkan-intel vulkan-tools i2c-tools
        break;;
    A | a)
        echo "========= Installing AMD Graphics ========="
        pacman -S --noconfirm xf86-video-amdgpu mesa vulkan-driver vulkan-tools i2c-tools
        while true; do
            read -p "Are you using a [A]MD GPU or a [R]eadon GPU? " subgpu
            case $subgpu in
            A | a)
                pacman -S --noconfirm amdvlk lib32-amdvlk
                break;;
            R | r)
                pacman -S --noconfirm vulkan-radeon lib32-vulkan-radeon
                break;;
            *) echo "Invaild Input";;
            esac
        done
        break;;
    N | n)
        echo "========= Installing Nvidia Graphics ========="
        pacman -S --noconfirm nvidia nvidia-utils nvidia-settings vulkan-driver lib32-nvidia-utils vulkan-tools i2c-tools
        break;;
    *) echo "Invalid input" ;;
    esac
done


echo "====== Installing font packs ======"
pacman -S --noconfirm dina-font tamsyn-font bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji

#DE Install
while true; do
    echo "What desktop environment do you want to install?"
    read -p "[X]fce, [G]nome, [K]DE, or [C]innamon? " de
    case $de in
    X | x) # XFCE
        echo "Installing XFCE and basic desktop apps"
        pacman -S --noconfirm xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies firefox simplescreenrecorder arc-gtk-theme arc-icon-theme papirus-icon-theme vlc x11-ssh-askpass file-roller geeqie libreoffice-fresh xournalpp xclip copyq syncthing discord catfish isync xreader simple-scan gparted octave pavucontrol gtop qalculate-gtk deluge-gtk baobab nemo nemo-fileroller nemo-preview nemo-seahorse nemo-share nemo-terminal appmenu-gtk-module
        systemctl enable lightdm
        pacman -R --noconfirm ristretto
        if [ "$use_bluetooth" = "yes" ]; then
            echo "Installing GUI for bluetooth"
            pacman -S --noconfirm blueman
        fi
        break;;
    G | g) # Gnome
        echo "Installing Gnome and basic desktop apps"
        pacman -S --noconfirm xorg gdm gnome gnome-extra firefox gnome-tweaks simplescreenrecorder arc-gtk-theme arc-icon-theme papirus-icon-theme vlc x11-ssh-askpass file-roller libreoffice-fresh syncthing discord isync simple-scan gparted octave pavucontrol gtop qalculate-gtk transmission baobab copyq
        systemctl enable gdm
        if [ "$use_bluetooth" = "yes" ]; then
            echo "Installing GUI for bluetooth"
            pacman -S --noconfirm blueman
        fi
        break;;
    K | k) # KDE
        echo "Installing KDE and basic desktop apps"
        pacman -S --noconfirm xorg sddm plasma kde-applications firefox simplescreenrecorder papirus-icon-theme ksshaskpass libreoffice-fresh syncthing discord isync simple-scan octave pavucontrol-qt gtop qalculate-qt qbittorrent filelight copyq
        systemctl enable sddm
        if [ "$use_bluetooth" = "yes" ]; then
            echo "Installing GUI for bluetooth"
            pacman -S --noconfirm bluedevil
        fi
        break;;
    C | c) #Cinnamon
        echo "Installing Cinnamon and basic desktop apps"
        pacman -S --noconfirm xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings cinnamon firefox simplescreenrecorder arc-gtk-theme arc-icon-theme papirus-icon-theme gnome-shell x11-ssh-askpass libreoffice-fresh file-roller nemo-fileroller syncthing discord isync simple-scan gparted octave pavucontrol gtop qalculate-gtk deluge-gtk baobab copyq
        if [ "$use_bluetooth" = "yes" ]; then
            echo "Installing GUI for bluetooth"
            pacman -S --noconfirm blueman
        fi
        break;;
    *) echo "Invalid input" ;;
    esac
done

#Systemd-boot or Grub Selector
while true; do
    read -p "What bootloader do you want to use? [G]rub, or [S]ystem-Boot?: " boot
    case $boot in
    S | s)
        echo "========= Installing Systemd-Boot ========="
        bootctl --path=/boot install
        echo "Creating Boot Configurations"
        microcode_hook=""
        if [ "$microcode" = "amd" ]; then microcode_hook="/amd-ucode.img"; fi
        if [ "$microcode" = "intel" ]; then microcode_hook="/intel-ucode.img"; fi
        sed -i '/timeout/s/^#//g' /boot/loader/loader.conf
        sed -i '/default/s/^/#/g' /boot/loader/loader.conf
        echo "default arch-*.conf" >> /boot/loader/loader.conf
        touch /boot/loader/entries/arch-latest.conf
        echo "title  ArchLinux" >> /boot/loader/entries/arch-latest.conf
        echo "linux   /vmlinuz-linux" >> /boot/loader/entries/arch-latest.conf
        echo "initrd  ${microcode_hook}" >> /boot/loader/entries/arch-latest.conf
        echo "initrd  /initramfs-linux.img" >> /boot/loader/entries/arch-latest.conf

        root_uuid="$(findmnt -no UUID -T /)"
        root_flags="root=UUID=${root_uuid}"
        swap_flags=""

        if [ "$use_crypt" = "yes" ]; then
            root_flags="cryptdevice=[UUID of entire device where cryptroot is located]:cryptroot ${root_flags}"
        fi

        if [ "$use_btrfs" = "yes" ]; then
            root_flags="${root_flags} rootflags=subvolid=[RootSubvolID],subvol=[RootSubvolName]"
        fi

        if [ "$use_swap" = "yes" ]; then
            swap_uuid="$(findmnt -no UUID -T /swap/swapfile)"
            swap_offset="$(sudo filefrag -v /swap/swapfile | awk '{ if($1=="0:"){print substr($4, 1, length($4)-2)} }')"

            swap_flags="resume=UUID=${swap_uuid} resume_offset=${swap_offset}"
        fi

        echo "options rw ${root_flags} ${swap_flags}" >> /boot/loader/entries/arch-latest.conf
        break;;
    G | g)
        echo "========= Installing GRUB ========="
        echo "This doesn't do anything yet!";;
    #break;;
    *) echo "Invalid input" ;;
    esac
done

echo "========= Configuring mkinitcpio ========"
extra_hooks=""

if [ "$use_swap" = "yes" ]; then extra_hooks="resume ${extra_hooks}"; fi

if [ "$use_btrfs" = "yes" ]; then
    extra_hooks="btrfs ${extra_hooks}"
    sed -i '57s/.//' /etc/mkinitcpio.conf
fi

if [ "$use_lvm" = "yes" ]; then extra_hooks="lvm ${extra_hooks}"; fi

if [ "$use_crypt" = "yes" ]; then extra_hooks="encrypt ${extra_hooks}"; fi

if [[ "${extra_hooks}" ]]; then
    echo "Put these in HOOKS: ${extra_hooks}" >> /etc/mkinitcpio.conf
    echo "IMPORTANT: Do not forget to put these parameters in the HOOKS section of /etc/mkinitcpio.conf! ${extra_hooks}"
    echo "The order of the hooks matter! The 'encrypt' hook goes before 'filesystems' , 'lvm' goes after 'filesystems', 'btrfs' goes after 'lvm', and finally, 'resume' goes at the very end of the paramter list"
fi
printf "\e[1;32mDone! Check all modified files to ensure installation was correctly done, check logs.txt and find the 'IMPORTANT' tags in the logs, they tell you important things you need to do next before rebooting. After verification, type exit, umount -a and reboot.\e[0m"
