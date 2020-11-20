#!/bin/bash

function enable_overlays
{
	# Detect SoC
	_soc=$(get_soc)
	[[ -z ${_soc} ]] && return 0

	# Detect board type
	_board_id=$(get_board_id)
	if [ "${_soc}" = "sun50i-a64" ] ; then
		_board_id="a64"
	fi
	if [ -z ${_board_id} ] && [ "${_soc}" = "sun4i-a10" ] ; then
		_board_id="a10"
	fi

	[[ -z ${_board_id} ]] && return 0

	# update uEnv.txt with default overlays
	_board_defaults_file="/usr/share/olinuxino/default/overlays/${_board_id}"
	if [ -f "${_board_defaults_file}" ] ; then
		for _overlay in $(cat "${_board_defaults_file}"); do
			_overlay="/usr/lib/olinuxino-overlays/${_soc}/${_overlay}"
			[[ ! -f "${_overlay}" ]] && continue
			[[ -z ${_overlays} ]] && _overlays="${_overlay}" || _overlays="${_overlays} ${_overlay}"
		done
		if [ -n "${_overlays}" ] ; then
			sed -i 's#^fdtoverlays=$#fdtoverlays='"${_overlays}"'#g' /boot/uEnv.txt
		fi
	fi
}

function get_board_id
{
    # TODO: cleanup this
    i2c_adapter=1
    if [ "$(cat /sys/class/i2c-adapter/i2c-0/name 2>/dev/null)" = "sun4i_hdmi_i2c adapter" ] ; then
      i2c_adapter=2
    fi
    local BOARD_ID=""
    for comp in $(cat "/proc/device-tree/compatible" | tr '\0' '\n'); do
	    if [[ "$comp" == "olimex,"* ]]; then
		    BOARD_ID=$((16#$(i2cget -f -y $i2c_adapter 0x50 0x04 w 2>/dev/null | sed 's/0x//g')))
		    if [ "${BOARD_ID}" == "0" ] ; then
			BOARD_ID=""
		    fi
		    break
	    fi
    done

    echo ${BOARD_ID}
}


function get_board
{
    local BOARD=""

    for comp in $(cat "/proc/device-tree/compatible" | tr '\0' '\n'); do
	    if [[ "$comp" == "olimex,"* ]]; then
		    BOARD=$(cut -d',' -f2 <<< $comp)
		    break
	    fi
    done

    echo ${BOARD}
}

function get_soc
{
    local SOC=""

    for comp in $(cat "/proc/device-tree/compatible" | tr '\0' '\n'); do
	    if [[ "$comp" == "allwinner,sun"* ]]; then
		    SOC=$(cut -d',' -f2 <<< $comp)
		    break
	    fi
    done

    echo ${SOC}
}

function get_root_partuuid
{
    local PARTUUID=""

    for arg in $(cat /proc/cmdline); do
        case $arg in
        "root="*)
                UUID=${arg#root=}
                break
            ;;

        *)
            ;;

        esac
    done

    echo ${PARTUUID}
}

function get_root_uuid
{
    local UUID=""

    while read line; do
        _uuid=$(awk '{print $1}' <<< "$line")
        _mount=$(awk '{print $2}' <<< "$line")
        [[ "${_mount}" =~ ^[/]$ ]] && \
            UUID="${_uuid#UUID=}" && \
            break
    done <<< $(grep -v ^# /etc/fstab)

    echo ${UUID}
}

function get_partition_by_uuid
{
    local UUID=$1

    blkid | grep "${UUID#UUID=}" | cut -d':' -f1
}

function get_partition_by_partuuid
{
    local PARTUUID=$1

    blkid | grep "${PARTUUID#PARTUUID=}" | cut -d':' -f1
}

function get_device_by_partition
{
    local PARTITION=$1

     # The following doesn't work on debian sid.
    DEVICE=$(lsblk -n -o PKNAME "${PARTITION}" | head -n1)

    # Try regex expression
    if [[ -z ${DEVICE} ]]; then
        [[ ${PARTITION} =~ "/dev/mmcblk"[0-9]+ ]] || \
        [[ ${PARTITION} =~ "/dev/sd"[a-z] ]] && \
        DEVICE=${BASH_REMATCH[0]}
    else
        DEVICE="/dev/${DEVICE}"
    fi

    echo ${DEVICE}
}

function get_root_partition
{
    local UUID=$(get_root_uuid)

    [[ -z ${UUID} ]] && return ""

     get_partition_by_uuid ${UUID}
}

function get_root_device
{
    local PARTITION=$(get_root_partition)

    [[ -z ${PARTITION} ]] && return ""

    get_device_by_partition ${PARTITION}

}

function get_emmc_device
{
    local ROOT_DEVICE=$(get_root_device)
    lsblk -l | grep "^mmcblk"[[:digit:]][[:digit:]]*[[:space:]] | grep -v ${ROOT_DEVICE#/*/} | awk '{print "/dev/"$1}'
}

function get_sata_device
{
    local ROOT_DEVICE=$(get_root_device)
    lsblk -l | grep "^sda"* | grep -v ${ROOT_DEVICE#/*/} | awk '{print "/dev/"$1}' | head -n1
}

function get_device_block_count
{
    blockdev --getsz $1
}

function get_partition_type
{
    local TYPE=""

    for arg in $(blkid | grep "^$1" | cut -d':' -f2); do
        case ${arg} in
        "TYPE="*)
            TYPE=$(sed 's/"//g' <<< ${arg#TYPE=})
            ;;
        *)
            ;;
        esac
    done

    echo ${TYPE}
}

function get_partition_uuid
{
    local UUID=""

    for arg in $(blkid | grep "^$1" | cut -d':' -f2); do
        case ${arg} in
        "UUID="*)
            UUID=$(sed 's/"//g' <<< ${arg#UUID=})
            ;;
        *)
            ;;
        esac
    done

    echo ${UUID}
}

function get_partition_start_block
{
    local START=""
    local DEVICE=$(get_device_by_partition $1)

    while read -r line; do
        grep -q "^$1" <<< "${line}" || continue

        START=$(awk -F' ' '{print $2}' <<< "${line}")
    done <<< "$(fdisk -l "${DEVICE}")"

    echo ${START}
}

function get_disklabel_type
{
    TYPE=$(fdisk -l $1 | grep "Disklabel type: " | awk '{print $3}')

    echo ${TYPE}
}

function resize_partition
{
    local PARTITION=$1
    local DEVICE=$(get_device_by_partition ${PARTITION})

    local TYPE=$(get_disklabel_type "${DEVICE}")
    if [ "${TYPE}" == "gpt" ] ; then
        sgdisk -e "${DEVICE}"
        sgdisk -d 4 "${DEVICE}"
        sgdisk -N 4 "${DEVICE}"
        partprobe "${DEVICE}"
        sgdisk -A 4:set:2 "${DEVICE}"
    else
        local START=$(get_partition_start_block ${PARTITION})
        if [ "${DEVICE}" != "/dev/sda" ] ; then
            local COUNT=$(fdisk -l "${DEVICE}" | grep -c "^${DEVICE}p")
            local DEVICEP="${DEVICE}p"
        else
            local COUNT=$(fdisk -l "${DEVICE}" | grep -c "^${DEVICE}")
            local DEVICEP="${DEVICE}"
        fi

        # Commands are different for single and multi-partition devices
        if [[ ${COUNT} -eq 1 ]]; then
            fdisk "${DEVICE}" > /dev/null 2>&1 << __EOF__
d
n
p
1
${START}

w
__EOF__
        else
            fdisk "${DEVICE}" << __EOF__
d
${PARTITION#${DEVICEP}}
n
p
${PARTITION#${DEVICEP}}
${START}

w
__EOF__
        fi
    fi
}
