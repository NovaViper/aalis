#!/usr/bin/env bash

set -e # Make script fail if something fails

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # Locate and save the script's current base directory
VERSION=3.2.1 # The current version of the script

if [[ "$VERSION" == "*-*" ]]; then
	ONLINE_VERSION=$(curl -s 'https://gitlab.com/api/v4/projects/31469197/releases' | grep tag_name | cut -d':' -f2 | cut -d'"' -f2)
else
	ONLINE_VERSION=$(curl -s 'https://gitlab.com/api/v4/projects/31469197/releases' | grep tag_name | cut -d ':' -f2 | cut -d'"' -f2 | tr -d -- "-rc")
fi
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

banner ${LIGHT_PURPLE} "Checking if script is update to date..."

if [[ "$VERSION" == "*-*" ]]; then
	output ${LIGHT_BLUE} "Checking for Stable/Beta Builds..."
else
	output ${LIGHT_BLUE} "Checking for Stable Builds..."
fi
test_compare_versions $VERSION $ONLINE_VERSION || :
sleep 2

banner ${LIGHT_PURPLE} "Setting font size"
installPac "terminus-font figlet"
setfont ter-v22b
clear


output ${LIGHT_PURPLE} "$(figlet -pctf big "Advanced ArchLinux Install Script")"
output ${LIGHT_BLUE} "$(figlet -kctWf big "AALIS v${VERSION}")"
output ${LIGHT_RED} "$(figlet -kctWf term "~ AALIS in Archland! ~")"

if [[ "yes" == $(askYesNo "Would you like to start the install?") ]]; then
	output ${LIGHT_GREEN} "Lets begin the installation!"
else
	output  ${LIGHT_RED} "Ok, I'm leaving then!"
	exit 1;
fi

bash 0-preinstall.sh
cp -R ${SCRIPT_DIR} /mnt/root/aalis
arch-chroot /mnt /root/aalis/1-setup.sh
if [ -f /mnt/root/aalis/sysconfig.conf ]; then source /mnt/root/aalis/sysconfig.conf; else output ${LIGHT_RED} "Cannot find /mnt/root/aalis/sysconfig.conf, cannot continue!"; sleep 2; exit 1; fi

for i in "${users[@]}"; do
	output ${YELLOW} "Running user setup for $i"
	arch-chroot /mnt /usr/bin/runuser -u $i -- /home/$i/aalis/2-user.sh

	if [[ "$desktop_env" == "kde"  ]] && [[ "$use_dracula_theme" == "yes" ]]; then
		output ${YELLOW} "Adding Dracula Kvantum theme for $i"
		mkdir -p /mnt/home/$i/.config
		cp -R ${SCRIPT_DIR}/premade-configs/dracula-theme-files/kde/config/. /mnt/home/$i/.config
		cp -R ${SCRIPT_DIR}/premade-configs/dracula-theme-files/kde/home/. /mnt/home/$i/
	fi

	output ${YELLOW} "Sending $i install log to main script directory"
	cp /mnt/home/$i/aalis/logs/user.log /mnt/root/aalis/logs/user_$i.log
	rm -Rf /mnt/home/$i/aalis
done
arch-chroot /mnt /root/aalis/3-post-setup.sh

banner ${LIGHT_PURPLE} "Cleaning up the system"
cp -R /mnt/root/aalis/logs/. ${SCRIPT_DIR}/logs
cp -R /mnt/root/aalis/sysconfig.conf ${SCRIPT_DIR}
rm -Rf /mnt/root/aalis

banner ${LIGHT_GREEN} "ALL DONE!! CHECK ALL OF THE LOG FILES IN THE LOG FOLDER AND CHECK" "FOR LINES WITH THE IMPORTANT TAG. THEN EJECT MEDIA AND RESTART!"
