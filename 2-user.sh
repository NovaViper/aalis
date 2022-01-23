#!/usr/bin/env bash

#Variable declarations
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # Locate and save the script's current base directory

#Enable logging!
touch ${SCRIPT_DIR}/logs/user.log
exec &> >(tee ${SCRIPT_DIR}/logs/user.log)

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then source ${SCRIPT_DIR}/sysconfig.conf; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/sysconfig.conf!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/sysconfig.conf, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2

if [[ $(sudo pacman -Qs --color always "emacs" | grep "local" | grep "emacs ") ]]; then
	banner ${LIGHT_PURPLE} "Enabling Emacs User Systemd service"
	sudo systemctl --user enable emacs
fi

banner ${LIGHT_PURPLE} "Installing AUR Software"
output ${YELLOW} "Installing Yay"
cd ~
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ~
rm yay-bin -rf

output ${YELLOW} "Installing ssh-agent Systemd Service"
installYay "systemd-ssh-agent"
sudo systemctl --user enable ssh-agent.service

if [[ "$shell_type" == "zsh" && "$use_shell_type_plugins" == "yes" ]]; then
	output ${YELLOW} "Installing ZSH Plugin Manager"
	installYay "zinit-git"

	if [[ ! "$use_lean_config" == "yes" ]]; then
		output ${YELLOW} "Installing Extra ZSH Packages for NovaViper's Configurations"
		installYay "pfetch-git zinit-git ttf-meslo-nerd-font-powerlevel10k"
	fi
fi

if [[ "$term_editor" == "neovim" && "$use_term_editor_plugins" == "yes" ]]; then
	output ${YELLOW} "Installing Neovim Plugin Manager"
	installYay "neovim-plug-git"
fi

if [[ "$use_dracula_theme" == "yes" ]]; then
	output ${YELLOW} "Installing main Dracula theme package"
	installYay "ant-dracula-theme-git"

	output ${YELLOW} "Installing QT apps Dracula theme package"
	installYay "ant-dracula-kvantum-theme-git"
fi

output ${YELLOW} "Installing Pamac"
output ${LIGHT_BLUE} "Note: The package archlinux-appstream-data-pamac will conflict with archlinux-appstream-data, please allow archlinux-appstream-data-pamac to install in order to install Pamac. Also allow all defaults by hitting the Enter key."
output ${LIGHT_BLUE} "I will give you 10 seconds to lead the above message."
sleep 10
installYaySoft "pamac-all"

if [[ "$is_laptop" == "yes" ]]; then
	output ${YELLOW} "Installing Laptop specific tools"
	installYay "tlpui"
fi

if [[ "$use_swap" == "yes"  ]]; then
	output ${YELLOW} "Installing ZRAM modules"
	installYay "zramd"
	sudo systemctl enable zramd.service
fi

if [[ "$use_yadm" = "yes" && "yes" == $(askYesNo "Would you like to import your dotfiles with yadm now?") ]]; then
	banner ${LIGHT_PURPLE} "Importing Yadm wizard"
	while true; do
		echo "Enter the URL for your Yadm repository. (Ex: https://github.com/exampledotfile))"
		read REPO
		if [[ ! -z "$REPO" ]];then
			output ${YELLOW} "Importing your yadm configuration..."
			yadm clone ${REPO}
			break
		else
			output ${LIGHT_RED} "This cannot be blank! Please try again!"
		fi
	done
	if [[ "yes" == $(askYesNo "Would you like to decrypt your encrypted yadm configurations? (You can choose to do this later!)") ]]; then
	   yadm decrypt
	fi
fi

if [[ "$use_desktop_env_aur" == "yes" ]]; then
	#DE Specific Install
	banner ${LIGHT_PURPLE} "Installing DE Specific AUR packages"
	if [[ "$desktop_env" == "xfce"  ]]; then
		output ${YELLOW} "Installing XFCE specific AUR packages"
		installYay "gnome-ssh-askpass3 menulibre mugshot"
		if [[ "yes" == $(askYesNo "Would you like to install Windowck (displays window title and buttons) and XFCE4 Docklike (Win 10-like taskbar) applets?") ]]; then
			installYay "xfce4-docklike-plugin-ng-git xfce4-windowck-plugin"
		fi
		if [[ "$is_laptop" == "yes" ]]; then
			output ${YELLOW} "Installing extra libinput packages"
			installYay "libinput-gestures"
		fi

	elif [[ "$desktop_env" == "gnome"  ]]; then
		output ${YELLOW} "Installing Gnome specific AUR packages"
		installYay "gnome-ssh-askpass3 menulibre mugshot"
		if [[ "$is_laptop" == "yes" ]]; then
			output ${YELLOW} "Installing extra libinput packages"
			installYay "libinput-gestures"
		fi

	elif [[ "$desktop_env" == "kde"  ]]; then
		output ${YELLOW} "Installing KDE specific packages"
		installYay "kde-servicemenus-pdf rootactions-servicemenu"
		if [[ "yes" == $(askYesNo "Would you like to install Appmenu, Window button, and Window title applets?") ]]; then
			installYay "plasma5-applets-window-appmenu-git plasma5-applets-window-buttons-git plasma5-applets-window-title-git"
		fi
		if [[ "$use_dracula_theme" == "yes" ]]; then
			output ${YELLOW} "Installing KDE specific Dracula theme package"
			installYay "ant-dracula-kde-theme-git"

			output ${YELLOW} "Adding Dracula SDDM theme for KDE"
			sudo touch /etc/sddm.conf
			sudo bash -c 'cat <<-EOF > /etc/sddm.conf
			[Theme]
			Current=Dracula
			EOF'
		fi
		if [[ "$is_laptop" == "yes" ]]; then
			output ${YELLOW} "Installing extra libinput packages"
			installYay "libinput-gestures"
		fi

	elif [[ "$desktop_env" == "cinnamon"  ]]; then
		output ${YELLOW} "Installing Cinnamon specific packages"
		installYay "gnome-ssh-askpass3 menulibre mugshot"
		if [[ "$is_laptop" == "yes" ]]; then
			output ${YELLOW} "Installing extra libinput packages"
			installYay "libinput-gestures"
		fi

	fi
fi

# Install user specified aur packages, filters out pacman packages from AUR packages
if [ -f ${SCRIPT_DIR}/premade-configs/packages/user_pkglist.txt ]; then
	banner ${LIGHT_PURPLE} "Installing Additional User Packages"
	installYay "$(comm -12 <(yay -Slaq | sort) <(sort ${SCRIPT_DIR}/premade-configs/packages/user_pkglist.txt))"
fi

output ${YELLOW} "Making yay ask to edit pkgbuild files and not ask for diff menu"
yay --editmenu --nodiffmenu --save

banner ${LIGHT_PURPLE} "SYSTEM READY FOR 3-post-install"
sleep 3
clear
