#!/usr/bin/bash

################################################################################
#  Name: chooseEFIBoot.sh
#  Date: 2022.10.5
#  Description:
#   Script for changing the next boot in EFI 
#   and lets you set a default boot
#
#  Dependencies:
#   bash        required, so it runs everywhere  
#   yad         required for the gui
#   efibootmgr  required 
#
#  Changes:
#	2022.10.30	VERSION=0.9	created README for GitHub 
#	2022.10.29	VERSION=0.8	updated all YAD outputs 
#	2022.10.27	VERSION=0.7	create functions setYADlist for simpler YAD handling
#				and setYADList for faster output
#	2022.10.18	VERSION=0.6 Changed the array way of handling the informations
#   2022.10.07  VERSION=0.5 Removed the non-English stuff added more comments
#               Mod Help file. Mod root enforced
#               Mod check for efibootmgr, yad
#               Mod most if [... replaced by [[ ... ]] && {  ... }.
#               Mod variable names for simple explanation.
################################################################################
# Primary language is English
# LANG=${LANG:=en_US.UTF-8}
# Linux REBOOT either reboot or shutdown -r # REBOOT="reboot" # Last Line 

# DEBUG
# set -o errexit
# set -o nounset
# set -o pipefail
# set -x
# [[ "${TRACE-0}" == "1" ]] { set -o xtrace; }

#### latest Version for help-info ############################################## 
VERSION="0.9"

#### Starting after main with help-info start program -h or -f filter sequence #
help-info() {
	yad --image "dialog-question" \
        --title "Some help - Using it is simple" \
        --on-top --center --width=640 --height=480 --button=OK:0 \
     	--list \
		--columns=2 \
		--column="*** Script must run as root ***" \
        		"Program version $VERSION
        		
bash $0  [-f filter 1]  [-f filter 2]  [-h]
		--filter	| -f	displays choosen filters
		--help	| -h	shows this output
		--reboot| -r	reboot as option
		
		Required: 
		EFI Boot Manager: $EFI 
		YAD Display Handler: $YAD" \
		--column="Current EFI Boot Information" \
		"`$EFI` "	
exit 1
}

#### User decides to boot or not ###############################################
final_decision() {
	yad --image "dialog-question" \
        --title "Reboot or not to reboot, that is the question" \
        --on-top --center --width=640 --height=480 --button=REBOOT:10 --button=CANCEL:0 \
	   	--list \
		--columns=2 \
		--column="*** Reboot Now ***" \
"Due to the great hidden wisdom 
of the EFI environment and its programmers 
a REBOOT is now required.

Or restart this program later to reboot then.

A reboot on your own or a regular shutdown 
may or may not work" \
		--column="Current EFI Boot Information" \
		"`$EFI` "	

[[ ${?} == 10 ]] && { echo  'R E B O O T'; } || { exit; }
}

#### We want root ##############################################################
[[ $(id -u) -ne 0 ]] && { help-info; }

#### let's find yad first#######################################################
YAD="yad"
[[ -z `which $YAD` ]] && { clear; echo "yad is not installed: apt install yad"; exit 1; }

#### let's find efibootmgr, should be in bin or sbin ###########################
EFI="efibootmgr"
[[ -z `which $EFI` ]] && { EFI="efibootmgr is not installed"; help-info; }

#### prepare cmd-line [Input] filter as indexed array ##########################
declare -a filter
export filter

[[ $# -eq 0 ]] && { filter[0]="showall"; } ## if cmd-line empty ################

#### prepare IFS to avoid breaks by space in efi_array based on efibootmgr #####
IFS=$'\n'
efi_array=(`$EFI`)
export efi_array

#### Prepares the Display for Yad ##############################################

setYADlist() { CBV="$1" NBV="$2" BL="$3"
	for (( i = $BL; i < ${#efi_array[@]}; i++ )); do
  		string=${efi_array[$i]}

		BNR=${string:4:4} # Boot Number
		NAM=${string:10:12} # EFI Name
		
		[[ $BNR == $CBV ]] && { CBF="TRUE"; } || { CBF="FALSE"; } # Current Boot Flag
		[[ $BNR == $NBV ]] && { NBF="TRUE"; } || { NBF="FALSE"; } # Next Boot Flag

#### filter contains showall shortcut
		[[ "${filter[0]}" == "showall" ]] && { echo $NBF; echo $CBF; echo $BNR; echo $NAM; continue; }

#### filter option pulled and filter exists upper lower case ?? ################		
		for actfilter in ${filter[*]}; do 
			[[ "$NAM" == *"${actfilter}"* ]] && { echo $NBF; echo $CBF; echo $BNR; echo $NAM; }
		done
	done 
} 

#### Read And Set - Prepares the Input from Yad ################################

readYADlist() { OBV="$1" 

CBV=${OBV:0:4} # Safety first

IFS="|" # Needed for columns out of YAD 

    while read NB SB NR EFINAME rest
    do
		[[ $NB == "TRUE" ]] && { [[ $CBV == $NR ]] && { return "0"; } || { break; } }    
	done

$EFI --bootnext $NR > /dev/null

return "10"
#### return 0 without change or with changes return 10 #########################
} 

################################################################################
# Here is main - Starting the whole enchilda
################################################################################

: main_course

while [[ -n "${1-}" ]] # catch $1 unbound error
do
	case "$1" in
		--help|-h|-H)
			help-info; exit
		;;
		--reboot|-r|-R)
			final_decision; exit
		;;
		--filter|-f|-F)
			filter[${#filter[*]}]="$2"; shift; shift; 
		;;
 		*)
        	help-info; exit
		;;
	esac
done

#### check BootNext to catch error - NB BootNext CB BootCurrent OB BootOrder ###
#### - if BootNext exists, BootCurrent shifts 1 position up in array ###########
#### - BL loop starts then with 4 else 3 ####################################### 

[[ ${efi_array[0]} = *"BootNext:"* ]] \
&& { NB=${efi_array[0]}; CB=${efi_array[1]};OB=${efi_array[3]}; BL=4; } \
|| { NB=${efi_array[0]}; CB=${efi_array[0]};OB=${efi_array[2]}; BL=3; }  

CBV=${CB:13:4}; OBV=${OB:11:50}; # pick up only the values

#### NBF New Boot Flag required if user change his mind later
[[ $BL = 4 ]] && { NBV=${NB:10:4}; NBF="TRUE"; } || { NBV=$CBV; NBF="FALSE"; }

#### yad output pipes to readAndSet and prepares EFI Array #####################
#### NBV Next Boot Value - CBV Current Boot Value - BL Boot Loop Start #########

setYADlist  "${CBV}" "${NBV}" "${BL}" | yad --image "dialog-question" \
	--title "Next and Current Boot"  \
	--on-top --center --width=640 --height=480 --button=OK:0 \
	--list \
	--columns=4 \
	--column="Next Boot":RD \
	--column="Current Boot":RD \
	--column="Boot Number" \
	--column="EFI Names" \
	--print-all | readYADlist  "${OBV}" # return is 0 or 10  

[[ $? -eq 10 ]] && final_decision # end of the enchilada  

exit
##########################################
# All Vars
# VERSION
# YAD Test if yad exists
# EFI efibootmgr program
# filter cmd line input as array 
# efi_array contains all the efi stuff
# CB Current Boot string BootCurrent 
# CBV Current Boot Value 
# CBF Current Boot Flag
# NB Next Boot string BootNext
# NBV Next Boot Value
# NBF Next Boot Flag
# BL Boot Loop
# BNR Boot Number
# NAM EFI Name
# OB Boot Order string BootOrder
# OBV Boot Order Value
