#!/usr/bin/env bash


yay -S pfetch-git ant-dracula-theme-git davmail git-credential-keepassxc kde-servicemenus mu neovim-plug-git pamac-all platformio plexamp-appimage ttf-meslo-nerd-font-powerlevel10k zinit-git


#DE Specific Install
while true; do
    echo "What desktop environment do you have installed?"
    read -p "[X]fce, [G]nome, [K]DE, or [C]innamon? " de
    case $de in
    X | x) # XFCE
        echo "Installing XFCE specific AUR packagess"
        yay -S
        break;;
    G | g) # Gnome
        echo "Installing Gnome specific AUR packages"
        yay -S
        break;;
    K | k) # KDE
        echo "Installing KDE specific packages"
        yay -S ant-dracula-kde-theme-git ant-dracula-kvantum-theme-git kde-servicemenus-pdf rootactions-servicemenu plasma5-applets-window-appmenu-git plasma5-applets-window-buttons-git plasma5-applets-window-title
        break;;
    C | c) #Cinnamon
        echo "Installing Cinnamon specific packages"
        yay -S
        break;;
    *) echo "Invalid input" ;;
    esac
done
