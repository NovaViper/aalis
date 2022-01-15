#!/usr/bin/env bash

# Variable Declarations
users=()
is_touchscreen=""
use_graphics=""
use_bluetooth=""
shell_type=""
root_use_shell_type=""
use_shell_type_plugins=""
term_editor=""
use_term_editor_plugins=""
use_lean_config=""
use_dracula_theme=""
microcode_type=""
use_minimal_install_mode=""
desktop_env=""
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # Locate and save the script's current base directory

#Enable logging!
touch ${SCRIPT_DIR}/logs/setup.log
exec &> >(tee ${SCRIPT_DIR}/logs/setup.log)

# Preflight check ensures that the script_funcs file (which holds all primary functions for the script)
# and the sysconfig.conf file (which holds all variables from previous steps of the script) are present.
# These files under any circumstance SHOULD NEVER be missing or really bad things will happen.
echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then source ${SCRIPT_DIR}/sysconfig.conf; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/sysconfig.conf!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/sysconfig.conf, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2


if [[ "yes" == $(askYesNo "Would you like to install in minimal mode?") ]]; then use_minimal_install_mode="yes"; fi

if [[ "yes" == $(askYesNo "Would you like to install the Dracula theme?") ]]; then use_dracula_theme="yes"; fi

banner ${LIGHT_PURPLE} "Configuring Pacman"
sed -i 's/^#Color/Color/' /etc/pacman.conf # Enable colored output
if [[ "$use_minimal_install_mode" != "yes" ]]; then sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf; fi # Enable 32bit library fr Steam
sed -i 's/^#Para/Para/' /etc/pacman.conf # Enable Parallel downloading for faster installation
pacman -Syu

banner ${LIGHT_PURPLE} "Setup Language to US and set locale, and hostname"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl set-ntp true
timedatectl set-timezone America/Chicago
systemctl enable systemd-timesyncd
hwclock --systohc
localectl set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
localectl set-keymap us # Set keymaps
installPac "hunspell-en_us"
read -p 'Hostname: ' hostname
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "127.0.0.1 $hostname" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
#Configure sudoers to allow every user under the wheel group to use sudo
sed -i 's/^# %wheel ALL=(ALL)/%wheel ALL=(ALL)/' /etc/sudoers

banner ${LIGHT_PURPLE} "Installing Base System Packages"
installPac "base base-devel linux linux-firmware reflector git gnupg networkmanager dhclient dialog wpa_supplicant wireless_tools netctl inetutils openssh"

systemctl enable NetworkManager
systemctl enable sshd
systemctl enable reflector.timer

banner ${LIGHT_PURPLE} "Installing Filesystem Packages"
installPac "ntfs-3g nfs-utils e2fsprogs smartmontools btrfs-progs gvfs gvfs-smb unzip unrar p7zip unarchiver"

banner ${LIGHT_PURPLE} "Configuring XDG User Directories"
installPac "xdg-user-dirs xdg-utils"
xdg-user-dirs-update # Updates user directories for XDG Specification

output ${YELLOW} "Configuring environment variables for XDG specification"
echo >> /etc/profile
echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> /etc/profile
echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> /etc/profile
echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> /etc/profile
echo 'export XDG_STATE_HOME="$HOME/.local/state"' >> /etc/profile
echo 'export GOPATH="$XDG_DATA_HOME/go"' >> /etc/profile
echo 'export CARGO_HOME="$XDG_DATA_HOME/cargo"' >> /etc/profile
echo 'export LESSHISTFILE="$XDG_CONFIG_HOME/less/history"' >> /etc/profile
echo 'export LESSKEY="$XDG_CONFIG_HOME/less/keys"' >> /etc/profile
echo 'export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm"' >> /etc/profile

if [[ "$use_dracula_theme" == "yes" ]]; then
    output ${YELLOW} "Configuring environment variables for Dracula theme"
    echo "QT_STYLE_OVERRIDE=kvantum" >> /etc/environment
    echo "GTK_THEME='Ant-Dracula'" >> /etc/environment
fi

# Shell Type configuration selection, asks user what shell they want ot use
while true; do
    read -p "$(output ${YELLOW} "What shell do you want to use? [B]ash, [Z]sh, [F]ish?: ")" shell
    case $shell in
    B | b)
        output ${YELLOW} "Ok, there is nothing else to do for Bash, so moving on!"
        shell_type="bash"
        break;;
    Z | z)
        output ${YELLOW} "========= Installing and setting up ZSH ========="
        shell_type="zsh"
        installPac "zsh"

        # This forces ZSH to use XDG specification
        cp ${SCRIPT_DIR}/zshenv /etc/zsh/zshenv

        if [[ "yes" == $(askYesNo "Would you like to make the root user use ZSH?") ]]; then
            output ${YELLOW} "Changing root shell"
            root_use_shell_type="yes"
            chsh -s /bin/zsh
        fi

        #Minimal Selection for ZSH, asks user if they want to use predefined configurations or just start off blank
        if [[ "$use_minimal_install_mode" != "yes" ]]; then
            if [[ "yes" == $(askYesNo "Would you like to use NovaViper's ZSH settings and plugins?") ]]; then
                output ${YELLOW} "Adding NovaViper's ZSH Settings"
                installPac "fzf subversion"
                use_shell_type_plugins="yes"

                #Place zshrc files in skel folder so users can get them
                mkdir -p /etc/skel/.config/zsh
                cp ${SCRIPT_DIR}/zshrc /etc/skel/.config/zsh/.zshrc

                # Add custom ZSH config for root user if prompted
                if [[ "$root_use_shell_type" == "yes" ]]; then
                    cp ${SCRIPT_DIR}/zshrc /etc/zsh/zshrc
                fi
            else
                if [[ "yes" == $(askYesNo "Would you like to use a lean ZSH configuration with a few plugins? (autosuggestion,syntax highlighting,autocompletion,history search)") ]]; then
                    output ${YELLOW} "Adding Minimal ZSH Settings"
                    use_shell_type_plugins="yes"
                    use_lean_config="yes"

                    #Place zshrc files in skel folder so users can get them
                    mkdir -p /etc/skel/.config/zsh
                    cp ${SCRIPT_DIR}/zshrc_min /etc/skel/.config/zsh/.zshrc

                    # Add custom ZSH config for root user if prompted
                    if [[ "$root_use_shell_type" == "yes" ]]; then
                        cp ${SCRIPT_DIR}/zshrc_min /etc/zsh/zshrc
                    fi
                else
                    output ${YELLOW} "Ok, skipping adding preconfigured zsh settings"
                fi
            fi
        fi
        break;;
    F | f)
        output ${YELLOW} "========= Installing and setting up Fish ========="
        shell_type="fish"
        installPac "fish"

        if [[ "yes" == $(askYesNo "Would you like to make the root user use Fish?") ]]; then
            output ${YELLOW} "Changing root shell"
            root_use_shell_type="yes"
            chsh -s /bin/fish
        fi
        break;;
    *) output ${LIGHT_RED} "Invalid input" ;;
    esac
done

# Terminal Text editor selector
while true; do
    read -p "$(output ${YELLOW} "What terminal text editor do you want to use? [N]ano, Neov[I]m, [V]im, [E]macs: ")" editor
    case $editor in
    N | n)
        output ${YELLOW} "========= Installing Nano ========="
        term_editor="nano"
        installPac "nano"
        break;;
    I | i)
        output ${YELLOW} "========= Installing Neovim ========="
        term_editor="neovim"
        installPac "neovim"

        mkdir -p /etc/skel/.config/nvim

        # Minimal selection for Neovim
        if [[ "$use_minimal_install_mode" != "yes" ]]; then
            if [[ "yes" == $(askYesNo "Would you like to use NovaViper's Neovim settings and plugins?") ]]; then
                output ${YELLOW} "Adding NovaViper's Neovim Settings"
                use_term_editor_plugins="yes"

                #Place neovim files in skel folder so users can get them
                cp ${SCRIPT_DIR}/init.vim /etc/skel/.config/nvim/init.vim
                cp ${SCRIPT_DIR}/plugins.vim /etc/skel/.config/nvim/plugins.vim
            else
                if [[ "yes" == $(askYesNo "Would you like to use a lean Neovim configuration with a few plugins? (vim-airline, vim-fugitive, vim-gitgutter)") ]]; then
                    output ${YELLOW} "Adding Minimal Neovim Settings"
                    use_term_editor_plugins="yes"
                    use_lean_config="yes"

                    #Place neovim files in skel folder so users can get them
                    mkdir -p /etc/skel/.config/nvim
                    cp ${SCRIPT_DIR}/init_min.vim /etc/skel/.config/nvim/init.vim
                    cp ${SCRIPT_DIR}/plugins_min.vim /etc/skel/.config/nvim/plugins.vim
                else
                    output ${YELLOW} "Ok, skipping adding preconfigured neovim settings"
                fi
            fi
        fi
        break;;
    V | v)
        output ${YELLOW} "========= Installing Vim ========="
        term_editor="vim"
        installPac "vim"

        output ${YELLOW} "Adding Vim XDG paths"
        mkdir -p /etc/skel/.cache/vim/{undo,swap,backup} /etc/skel/.config/vim/after /etc/skel/.local/share/vim
        cp ${SCRIPT_DIR}/vimrc /etc/skel/.config/vim/vimrc # Sends premade vimrc file with XDG configurations to skel folder for other users to use
        echo 'export GVIMINIT='let $MYGVIMRC="$XDG_CONFIG_HOME/vim/gvimrc" | source $MYGVIMRC'' >> /etc/profile
        echo 'export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'' >> /etc/profile

        break;;
    E | e)
        output ${YELLOW} "========= Installing Emacs ========="
        term_editor="emacs"
        installPac "emacs"
        break;;
    *) output ${LIGHT_RED} "Invalid input" ;;
    esac
done

if [[ "$term_editor" != "emacs" && "yes" == $(askYesNo "Would you like to install Emacs also for other tasks?") ]]; then
    output ${YELLOW} "========= Installing Emacs ========="
    installPac "emacs"
fi

banner ${LIGHT_PURPLE} "Adding and Configuring Users"
addRootPass

#Additional User Prompt
while [[ "yes" == $(askYesNo "Would you like to add any additional users?") ]]; do addUserPass; done

#Configure Shell environments for additional users
if [[ "${users[@]}" ]]; then
    if [[ "$shell_type" == "zsh" ]]; then
        output ${YELLOW} "====== Configuring additional users for ZSH ======"
        echo
        for i in "${users[@]}"; do
            usermod -s /bin/zsh $i
        done
    elif [[ "$shell_type" == "fish" ]]; then
        output ${YELLOW} "====== Configuring additional users for Fish ======"
        echo
        for i in "${users[@]}"; do
            usermod -s /bin/fish $i
        done
    fi
fi

banner ${LIGHT_PURPLE} "Configuring Base System"
if [[ "yes" == $(askYesNo "Do you want to install a graphical environment?") ]]; then
    output ${LIGHT_BLUE} "Ok, I will take you to the graphics installer, but first we still have some things to configure."
    use_graphics="yes"
    sleep 2
fi

if [[ "$is_laptop" == "yes" ]]; then
    output ${YELLOW} "Installing TLP and other battery management tools"
    installPac "acpi acpi_call tlp"
    systemctl enable tlp
fi

#Processor Microcode Installer
while true; do
    read -p "$(output ${YELLOW} "What brand is your processor? [I]ntel or [A]MD?: ")" processor
    case $processor in
    I | i)
        output ${YELLOW} "========= Installing Intel Microcode ========="
        microcode_type="intel"
        installPac "intel-ucode"
        break;;
    A | a)
        output ${YELLOW} "========= Installing AMD Microcode ========="
        microcode_type="amd"
        installPac "amd-ucode"
        break;;
    *) output ${LIGHT_RED} "Invalid input";;
    esac
done

## Graphics installer
if [[ "$use_graphics" == "yes" ]]; then
    banner ${LIGHT_PURPLE} "Installing Graphical Environment"
    sleep 1

    #Network Manager
    output ${YELLOW} "======= Installing GUI components for Network Manager ========"
    installPac "network-manager-applet networkmanager-openvpn openvpn"

    #Bluetooth
    if [[ "yes" == $(askYesNo "Would you like to download and enable Bluetooth?") ]]; then
        output ${YELLOW} "========= Installing Bluetooth ========="
        use_bluetooth="yes"
        installPac "bluez bluez-utils"
        sed -i "250s/.*/AutoEnable=true/" /etc/bluetooth/main.conf
        systemctl enable bluetooth
    fi

    #Laptop Touchscreen
    if [[ "$is_laptop" == "yes" && "yes" == $(askYesNo "Does your laptop have touchscreen capability?") ]]; then
        output ${YELLOW} "========= Installing Wacom settings ========="
        is_touchscreen="yes"
        installPac "libwacom xf86-input-wacom iio-sensor-proxy"
    fi

    #Audio Selection
    while true; do
        read -p "$(output ${YELLOW} "What audio driver would you like to install? Pulse[A]udio or Pipe[W]ire?: ")" audio
        case $audio in
        A | a)
            output ${YELLOW} "========= Installing PulseAudio protocols ========="
            installPac "alsa-utils pulseaudio pulseaudio-alsa pipewire-alsa gst-libav gst-plugins-ugly gst-plugins-bad"
            if [ "$use_bluetooth" == "yes" ]; then
                output ${YELLOW} "Installing Extra Bluetooth package for PulseAudio"
                installPac "pulseaudio-bluetooth"
            fi

            if [[ "yes" == $(askYesNo "Do you want to enable PulseAudio's echo-cancel module for Echo/Noise Cancellation of microphone inputs?")  ]]; then
                output ${YELLOW} "Enabling echo-cancel module"
                echo ".ifexists module-echo-cancel.so" >> /etc/pulse/default.pa
                echo "load-module module-echo-cancel aec_method=webrtc source_name=echocancel sink_name=echocancel1" >> /etc/pulse/default.pa
                echo "set-default-source echocancel" >> /etc/pulse/default.pa
                echo "set-default-sink echocancel1" >> /etc/pulse/default.pa
                echo ".endif" >> /etc/pulse/default.pa
            fi

            break;;
        W | w)
            output ${YELLOW} "========= Installing PipeWire protocols ========="
            installPac "alsa-utils pipewire pipewire-media-session pipewire-pulse pipewire-alsa gst-libav gst-plugins-ugly gst-plugins-bad"
            break;;
        *) output ${LIGHT_RED} "Invaild Input";;
        esac
    done

    #HP Printer configuration
    if [[ "yes" == $(askYesNo "Would you like to install HP Printer Modules?") ]]; then
        output ${YELLOW} "========= Installing HP modules ========="
        installPac "cups cups-filters hplip"
        systemctl enable cups
    fi

    #Installer based on instructions from: https://boseji.com/posts/manjaro-kvm-virtmanager/
    if [[ "yes" == $(askYesNo "Would you like to install Virt-Manager?") ]]; then
        output ${YELLOW} "========= Installing Virt-Manager, Qemu and other required packages ========="
        output ${LIGHT_BLUE} "Note: The package iptables-nft will conflict with iptables, please allow iptables-nft to install in order to use Virt-Manager's virutal ethernet feature."
        sleep 5
        installPacSoft "qemu libvirt iptables-nft dnsmasq virt-manager virt-viewer bridge-utils dmidecode edk2-ovmf"
        systemctl enable libvirtd
        output ${YELLOW} "====== Configuring KVM ======"
        sed -i '/unix_sock_group/s/^#//g' /etc/libvirt/libvirtd.conf
        sed -i '/unix_sock_rw_perms/s/^#//g' /etc/libvirt/libvirtd.conf
        virsh net-autostart default

        if [[ "${users[@]}" ]]; then
            output ${YELLOW} "====== Configuring additional users for libvirt ======"
            echo
            for i in "${users[@]}"; do
                usermod -a -G libvirt $i
            done
        fi
    fi
fi

#Graphics Card Driver Installer
while true; do
    read -p "$(output ${YELLOW} "What brand is your graphics? [I]ntel, [A]MD or [N]vidia?: ")" graphics
    case $graphics in
    I | i)
        output ${YELLOW} "========= Installing Intel Graphics ========="
        installPac "xf86-video-intel mesa"

        if [[ "$use_minimal_install_mode" != "yes" ]]; then
            output ${YELLOW} "Installing Intel Vulkan packages for Steam"
            installPac "vulkan-intel vulkan-driver lib32-mesa lib32-vulkan-intel vulkan-tools i2c-tools"
        fi
        break;;
    A | a)
        output ${YELLOW} "========= Installing AMD Graphics ========="
        installPac "xf86-video-amdgpu mesa"
        if [[ "$use_minimal_install_mode" != "yes" ]]; then
            while true; do
                read -p "$(output ${YELLOW}"Are you using a [A]MD GPU or a [R]eadon GPU? ")" subgpu
                case $subgpu in
                A | a)
                    output ${YELLOW} "Installing AMD Vulkan packages for Steam"
                    installPac "amdvlk lib32-amdvlk vulkan-driver vulkan-tools i2c-tools"
                    break;;
                R | r)
                    output ${YELLOW} "Installing Radeon Vulkan packages for Steam"
                    installPac "vulkan-radeon lib32-vulkan-radeon vulkan-driver vulkan-tools i2c-tools"
                    break;;
                *) output ${LIGHT_RED} "Invaild Input";;
                esac
            done
        fi
        break;;
    N | n)
        output ${YELLOW} "========= Installing Nvidia Graphics ========="
        installPac "nvidia nvidia-utils nvidia-settings"

        if [[ "$use_minimal_install_mode" != "yes" ]]; then
            output ${YELLOW} "Installing Nvidia Vulkan packages for Steam"
            installPac "lib32-nvidia-utils vulkan-tools i2c-tools vulkan-driver"
        fi
        break;;
    *) output ${LIGHT_RED} "Invalid input" ;;
    esac
done

if [[ "$use_minimal_install_mode" != "yes" ]]; then
    #Font packs install
    output ${YELLOW} "====== Installing font packs ======"
    installPac "dina-font tamsyn-font bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji"

    #Base user packages
    output ${YELLOW} "====== Installing base user packages ====="
    installPac "firefox vlc libreoffice-fresh discord htop appmenu-gtk-module"

    if [[ "yes" == $(askYesNo "Would you like to use the dotfiles manager, YADM?") ]]; then
        output ${LIGHT_BLUE} "Installing YADM"
        installPac "yadm"
    fi
else
    #Base user packages
    output ${YELLOW} "====== Installing base user packages ====="
    installPac "firefox vlc libreoffice-fresh discord htop appmenu-gtk-module"
fi



#DE Install
while true; do
    output ${YELLOW} "What desktop environment do you want to install?"
    read -p "$(output ${YELLOW} "[X]fce, [G]nome, [K]DE, or [C]innamon? ")" de
    case $de in
    X | x) # XFCE
        output ${YELLOW} "Installing XFCE and basic desktop apps"
        desktop_env="xfce"
        installPac "xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4 xfce4-goodies arc-gtk-theme arc-icon-theme file-roller catfish xreader gparted pavucontrol qalculate-gtk deluge-gtk baobab"
        systemctl enable lightdm
        output ${YELLOW} "Setting SSH_ASKPASS variable to gnome-ssh-askpass3 for gui ssh prompts"
        echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment

        # Ask to remove XFCE's ristretto program
        if [[ "yes" == $(askYesNo "Do you want to use geeqie instead of XFCE's default image viewer ristretto? geeqie has some features that risteretto is missing like saving edited images.") ]]; then
            installPac "geeqie"
            removePac "ristretto"
        fi
        # Use Bluetooth if the user wanted to install it
        if [ "$use_bluetooth" == "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            installPac "blueman"
        fi
        break;;

    G | g) # Gnome
        output ${YELLOW} "Installing Gnome and basic desktop apps"
        desktop_env="gnome"
        installPac "xorg gdm gnome gnome-extra gnome-tweaks arc-gtk-theme arc-icon-theme file-roller gparted pavucontrol qalculate-gtk transmission-gtk baobab"
        systemctl enable gdm
        output ${YELLOW} "Setting SSH_ASKPASS variable to gnome-ssh-askpass3 for gui ssh prompts"
        echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment

        # Use Bluetooth if the user wanted to install it
        if [ "$use_bluetooth" == "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            installPac "blueman"
        fi
        break;;

    K | k) # KDE
        output ${YELLOW} "Installing KDE and basic desktop apps"
        desktop_env="kde"
        installPac "xorg sddm ark audiocd-kio breeze-gtk dolphin dragon elisa gwenview kate kdeconnect kde-gtk-config khotkeys kinfocenter kinit kio-fuse konsole kscreen kwallet-pam kwalletmanager okular plasma-desktop plasma-disks plasma-nm plasma-pa powerdevil print-manager sddm-kcm solid spectacle xsettingsd plasma-browser-integration ksshaskpass pavucontrol-qt qalculate-qt qbittorrent filelight kdeplasma-addons quota-tools"
        systemctl enable sddm
        output ${YELLOW} "Setting SSH_ASKPASS variable to ksshaskpass for gui ssh prompts"
        echo "SSH_ASKPASS=/usr/bin/ksshaskpass" >> /etc/environment

        # Use Bluetooth if the user wanted to install it
        if [ "$use_bluetooth" == "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            installPac "bluedevil"
        fi

        # Install touchscreen laptop drivers if prompted to do so earlier
        if [[ "$is_laptop" == "yes" && "$is_touchscreen" == "yes" ]]; then
            output ${YELLOW} "Installing GUI for Wacom drivers"
            installPac "kcm-wacomtablet"
        fi

        # Add KWallet to pam for auto unlock
        output ${YELLOW} "Adding Kwallet to PAM"
        sed -i '4s/.//' /etc/pam.d/sddm
        sed -i '15s/.//' /etc/pam.d/sddm
        break;;

    C | c) #Cinnamon
        output ${YELLOW} "Installing Cinnamon and basic desktop apps"
        desktop_env="cinnamon"
        installPac "xorg lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings cinnamon arc-gtk-theme arc-icon-theme gnome-shell file-roller nemo-fileroller gparted pavucontrol qalculate-gtk deluge-gtk baobab xreader"
        systemctl enable lightdm
        output ${YELLOW} "Setting SSH_ASKPASS variable to gnome-ssh-askpass3 for gui ssh prompts"
        echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment

        # Use Bluetooth if the user wanted to install it
        if [ "$use_bluetooth" == "yes" ]; then
            output ${YELLOW} "Installing GUI for bluetooth"
            installPac "blueman"
        fi
        break;;
    *) output ${LIGHT_RED} "Invalid input" ;;
    esac
done

# Install user specified aur packages, filters out AUR packages from ArchLinux repo packages
if [ -f ${SCRIPT_DIR}/user_pkglist.txt ]; then
    banner ${LIGHT_PURPLE} "Installing Additional User packages"
    installPac "$(comm -12 <(pacman -Slq | sort) <(sort ${SCRIPT_DIR}/user_pkglist.txt))"
fi


output ${LIGHT_BLUE} "Saving Parameters for final step"
if [[ "${users[@]}" ]]; then echo "users=$users"            >> ${SCRIPT_DIR}/sysconfig.conf; fi
echo "is_touchscreen=$is_touchscreen"                       >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_graphics=$use_graphics"                           >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_bluetooth=$use_bluetooth"                         >> ${SCRIPT_DIR}/sysconfig.conf
echo "shell_type=$shell_type"                               >> ${SCRIPT_DIR}/sysconfig.conf
echo "root_use_shell_type=$root_use_shell_type"             >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_shell_type_plugins=$use_shell_type_plugins"       >> ${SCRIPT_DIR}/sysconfig.conf
echo "term_editor=$term_editor"                             >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_term_editor_plugins=$use_term_editor_plugins"     >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_lean_config=$use_lean_config"                     >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_dracula_theme=$use_dracula_theme"                 >> ${SCRIPT_DIR}/sysconfig.conf
echo "microcode_type=$microcode_type"                       >> ${SCRIPT_DIR}/sysconfig.conf
echo "use_minimal_install_mode=$use_minimal_install_mode"   >> ${SCRIPT_DIR}/sysconfig.conf
echo "desktop_env=$desktop_env"                             >> ${SCRIPT_DIR}/sysconfig.conf


if [ $(whoami) = "root"  ];
then
    for i in "${users[@]}"; do
        cp -R /root/aalis /home/$i/
        chown -R $i: /home/$i/aalis
    done
else
    output ${LIGHT_GREEN} "You are already a user, lets proceed with AUR installation"
fi

banner ${LIGHT_PURPLE} "SYSTEM READY FOR 2-user"
sleep 3
clear
