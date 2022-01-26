#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
if [ -f ${SCRIPT_DIR}/sysconfig.conf ]; then source ${SCRIPT_DIR}/sysconfig.conf; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/sysconfig.conf!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/sysconfig.conf, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2
clear


if [ -f ${SCRIPT_DIR}/logs/compiled.log ]; then output ${LIGHT_BLUE} "Removing old compiled.log";rm -rf ${SCRIPT_DIR}/logs/compiled.log; fi
output ${LIGHT_BLUE} "Compiling all logs..."
touch ${SCRIPT_DIR}/logs/compiled.log
cat <<-EOF >> ${SCRIPT_DIR}/logs/compiled.log
###############################################################################################################
###############################################################################################################
############################################ PREINSTALLATION PHASE ############################################
###############################################################################################################
###############################################################################################################

EOF
cat ${SCRIPT_DIR}/logs/preinstall.log >> ${SCRIPT_DIR}/logs/compiled.log


cat <<-EOF >> ${SCRIPT_DIR}/logs/compiled.log

#############################################################################################################
#############################################################################################################
############################################# INSTALLATION PHASE ############################################
#############################################################################################################
#############################################################################################################

EOF
cat ${SCRIPT_DIR}/logs/setup.log >> ${SCRIPT_DIR}/logs/compiled.log


for i in "${users[@]}"; do
	cat <<-EOF >> ${SCRIPT_DIR}/logs/compiled.log

	#####################################################################################################################
	#####################################################################################################################
	############################################ USER: $i INSTALLATION PHASE ############################################
	#####################################################################################################################
	#####################################################################################################################

	EOF
	cat ${SCRIPT_DIR}/logs/user_$i.log >> ${SCRIPT_DIR}/logs/compiled.log
done

cat <<-EOF >> ${SCRIPT_DIR}/logs/compiled.log

################################################################################################################
################################################################################################################
############################################ POSTINSTALLATION PHASE ############################################
################################################################################################################
################################################################################################################

EOF

cat ${SCRIPT_DIR}/logs/postinstall.log >> ${SCRIPT_DIR}/logs/compiled.log

output ${LIGHT_GREEN} "Done compiling!"
