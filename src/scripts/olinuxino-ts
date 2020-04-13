#!/bin/bash

# Check is LCD is enabled in the device tree
LCD=$(grep -r "lcd-olinuxino-[147]" /proc/device-tree -a -h | tr -d '\0')
[[ -z $LCD ]] && exit 0

# Select transformation matrix
case $LCD in
	"olimex,lcd-olinuxino-4.3")
		MATRIX="1.08 0.0 -0.04 0.0 1.14 -0.10 0.0 0.0 1.0"
		;;
	"olimex,lcd-olinuxino-7")
		MATRIX="1.06 0.0 -0.03 0.0 1.11 -0.08 0.0 0.0 1.0"
		;;
	"olimex,lcd-olinuxino-10")
		MATRIX="1.04 0.0 -0.03 0.0 1.09 -0.07 0.0 0.0 1.0"
		;;
	*)
		# The LCD is not supported by this script
		exit 0;
esac

# Generate configuration file
tee > /etc/X11/xorg.conf.d/98-screen-calibration.conf << __EOF__
Section "InputClass"
	Identifier	"calibration"
	MatchProduct	"1c25000.rtp"
	Option		"TransformationMatrix" "$MATRIX"
EndSection
__EOF__
