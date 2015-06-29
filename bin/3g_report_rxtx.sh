#!/bin/bash

#part of https://github.com/7890/3g_stick
#//tb/1506

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/3g_config.sh

for tool in {"$oscsend",cut}; \
	do checkAvail "$tool"; done

while [ 1 -eq 1 ] 
do
	/sbin/ifconfig -a | grep "${_3g_network_interface}" >/dev/null 2>&1
	ret=$?

	if [ $ret -eq 0 ]
	then
		rx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "RX bytes" | cut -d ":" -f2 | cut -d" " -f1`
		tx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "TX bytes" | cut -d ":" -f3 | cut -d" " -f1`
		$oscsend $osc_report_host $osc_report_port /gprs/rxtx ii $rx_bytes $tx_bytes
	fi
	sleep 1
done
