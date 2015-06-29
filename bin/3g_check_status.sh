#!/bin/bash

#part of https://github.com/7890/3g_stick
#//tb/1506

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/3g_config.sh

for tool in {"$sakis3g","$oscsend",cut,id}; \
	do checkAvail "$tool"; done

#check if script is started as root or sudo
user_id=`id -u`
if [ x"$user_id" != "x0" ]
then
	echo "run script as user root or with sudo."
	exit 1
fi

echo "checking sakis3g connection status"
echo "=================================="

$sakis3g --sudo "status" USBMODEM="$sakis_USBMODEM" USBINTERFACE="$sakis_USBINTERFACE" APN="$sakis_APN"

ret=$?

echo $ret

if [ x"$ret" = "x0" ]
then
	rx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "RX bytes" | cut -d ":" -f2 | cut -d" " -f1`
	tx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "TX bytes" | cut -d ":" -f3 | cut -d" " -f1`

	$oscsend $osc_report_host $osc_report_port /gprs/connection/alive ii $rx_bytes $tx_bytes
else
	$oscsend $osc_report_host $osc_report_port /gprs/connection/down
fi
