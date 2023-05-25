#!/usr/bin/bash

#------------------------------------------------------------------------------#
#  Name: efinewboot.sh
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
#------------------------------------------------------------------------------#
# Primary language is English
# LANG=${LANG:=en_US.UTF-8}
# Linux REBOOT either reboot or shutdown -r # REBOOT="reboot" # Last Line 
#
# DEBUG
# set -o errexit
# set -o nounset
# set -o pipefail
# set -x
# [[ "${TRACE-0}" == "1" ]] { set -o xtrace; }
#------------------------------------------------------------------------------#

# latest Version for help-info ------------------------------------------------#
 
VERSION="0.9"

#### Starting after main with help-info start program -h or -f filter sequence
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

#### User decides to boot or not 
final_decision() {
 
	read GO; read NR; addtxt=""
	[[ $BL -eq 3 ]]  && { addtxt="BootNext: $NR"; }	

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
may or may not work with EFI" \
		--column="Current EFI Boot Information" \
"$addtxt 
`$EFI`
"

#### If setlist reports TRUE and User say YES to Reboot then EFI is updated and
#### PC/Server reboots.  And everything is final
[[ $GO == "TRUE" && ${?} == 10 ]]  && { `$EFI --bootnext $BNR_OUT > /dev/null`; `reboot`; } || { exit 0; }
}

#### Prepares the Display for Yad 

setYADlist() { CBV="$1" NBV="$2" BL="$3"
	for (( i = $BL; i < ${#EFI_ARRAY[@]}; i++ )); do

		BNR=${EFI_ARRAY[$i]:4:4} # Boot Number
		NAM=${EFI_ARRAY[$i]:10:12} # EFI Name
	
		[[ $BNR == $CBV ]] && { CBF="TRUE"; } || { CBF="FALSE"; } # Current Boot Flag
		[[ $BNR == $NBV ]] && { NBF="TRUE"; } || { NBF="FALSE"; } # Next Boot Flag

#### filter contains showall shortcut
		[[ "${filter[0]}" == "showall" ]] && { echo $NBF; echo $CBF; echo $BNR; echo $NAM; continue; }

#### filter option pulled and filter exists upper lower case check ?? ###########		
		for actfilter in ${filter[*]}; do 
			[[ "$NAM" == *"${actfilter}"* ]] && { echo $NBF; echo $CBF; echo $BNR; echo $NAM; }
		done
	done 
} 

#### Read And Set - Prepares the Input from Yad 
readYADlist() { OBV="$1" 

IFS="|" # Needed for columns out of YAD 

    while read NBF_OUT CBF_OUT BNR_OUT NAM_OUT rest; do
   		[[ $NBF_OUT == "TRUE" ]] && { echo $NBF_OUT; echo $BNR_OUT; return 10; }  
   	done
   	
return 0 
} 

#### We want root 
[[ $(id -u) -ne 0 ]] && { echo "We need root"; }

#### let's find yad first
YAD="yad"
[[ -z `which $YAD` ]] && { clear; echo "yad is not installed: apt install yad"; exit 1; }

#### let's find efibootmgr, should be in bin or sbin
EFI="efibootmgr"
[[ -z `which $EFI` ]] && { EFI="efibootmgr is not installed"; help-info; }

#### prepare cmd-line [Input] filter as indexed array 
declare -a filter
export filter

[[ $# -eq 0 ]] && { filter[0]="showall"; } ## if cmd-line is empty

#### prepare IFS to avoid breaks by space in EFI_ARRAY based on efibootmgr
IFS=$'\n'
EFI_ARRAY=(`$EFI`)

#### Here is main - Starting the whole enchilda

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

#### check BootNext to catch user error - if BootNext exists, BootCurrent shifts
#### one position up in array - Boot Loop BL starts then with 4 else 3 
#### NB BootNext CB BootCurrent OB BootOrder 

[[ ${EFI_ARRAY[0]} = *"BootNext:"* ]] \
&& { NBS=${EFI_ARRAY[0]}; CBS=${EFI_ARRAY[1]};OBS=${EFI_ARRAY[3]}; BL=4; } \
|| { NBS=${EFI_ARRAY[0]}; CBS=${EFI_ARRAY[0]};OBS=${EFI_ARRAY[2]}; BL=3; }  

CBV=${CBS:13:4}; OBV=${OBS:11:50}; # pick up only the values

#### NBF New Boot Flag required if user change his mind later
[[ $BL = 4 ]] && { NBV=${NBS:10:4}; NBF="TRUE"; } || { NBV=$CBV; NBF="FALSE"; }

#### yad output pipes to readAndSet and prepares EFI Array 
#### NBV Next Boot Value - CBV Current Boot Value

setYADlist  "${CBV}" "${NBV}" "${BL}" | yad --image "dialog-question" \
	--title "Next and Current Boot"  \
	--on-top --center --width=640 --height=480 --button="gtk-ok:0" \
	--list \
	--columns=4 \
	--column="Next Boot":RD \
	--column="Current Boot":RD \
	--column="Boot Number" \
	--column="EFI Names" \
	--print-all | readYADlist  "${OBV}" | final_decision   # end of the enchilada  
exit
##########################################
# Most Vars
# VERSION
# YAD Test if yad exists
# EFI efibootmgr program
# filter cmd line input as array 
# EFI_ARRAY contains all the efi stuff
# CBS Current Boot string BootCurrent 
# CBV Current Boot Value 
# CBF Current Boot Flag
# NBS Next Boot string BootNext
# NBV Next Boot Value
# NBF Next Boot Flag
# BL Boot Loop
# BNR Boot Number
# NAM EFI Name
# OBS Boot Order string BootOrder
# OBV Boot Order Value
