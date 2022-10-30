# EFI-New-Boot
 
## Description

With the *efibootmgr* program you are able to handle *UEFI* issues. This bash script allows to choose and to select your next OS from your desktop and to boot it immediately. If your Linux/Unix works without *UEFI* it is pretty useless.

I use *YAD* as the GUI inside bash. 

## Dependencies 

Required is the good old bash. It should run with most newer versions.

yad, as the display manager : `apt install yad`

efibootmgr, the Linux UEFI manager: `apt install efibootmgr`

Normally any version and combination of the software above will do the job.

## Required 

Superuser power as in root. No mere mortal is allowed to play around with efi power.
+ su -p for a root shell: _# bash  ./efinewboot.sh 
+ sudo bash ./efinewboot.sh 
 
## Get help 

bash ./efinewboot.sh -h  opens the following screen

![Help Display](./efi-help.png)
 
+ efinewboot.sh -f ubuntu filters the output to ubuntu 
+ With efinewboot.sh -f ubuntu -f debian the display shows only the entries for ubuntu and debian. The number of filters is restricted to four [$1 - $9]
+ efinewboot.sh -r is a shortcut for a reboot  
## Start Display

![Sample Display](./efi-display.png)

You can only select the `Next Boot` buttons. 

## Final Display 

![Help Display](./efi-final.png "Help Display")

Reboot or Cancel everything. But fiddling with efibootmgr is tricky and a reboot is a safe bet.

## Changes
+ 2022.10.20 VERSION=0.9 created README
+ 2022.10.29 VERSION=0.8 updated all YAD outputs 
+ 2022.10.27 VERSION=0.7 create functions setYADlist for simpler YAD handling and setYADList for faster output
+ 2022.10.18 VERSION=0.6 Changed the array way of handling the informations
+ 2022.10.07 VERSION=0.5 Removed the non-English stuff added more comments
         Mod Help file. Mod root enforced
         Mod check for efibootmgr, yad
         Mod most if [... replaced by [[ ... ]] && {  ... }.
         Mod variable names for simple explanation.
         
## Tags

EFI UEFI EFIBOOTMGR LINUX UBUNTU MINT DEBIAN YAD 