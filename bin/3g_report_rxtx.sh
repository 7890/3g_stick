#!/bin/bash

#part of https://github.com/7890/3g_stick
#//tb/1506

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/3g_config.sh

while [ 1 -eq 1 ] 
do
	rx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "RX bytes" | cut -d ":" -f2 | cut -d" " -f1`
	tx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "TX bytes" | cut -d ":" -f3 | cut -d" " -f1`
	$oscsend $osc_report_host $osc_report_port /gprs/rxtx ii $rx_bytes $tx_bytes
	sleep 1
done
