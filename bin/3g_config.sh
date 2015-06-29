#!/bin/bash

#part of https://github.com/7890/3g_stick
#//tb/1506

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#. "$DIR"/3g_config.sh

#scripts, all in same directory as 3g_config.sh
check_status="$DIR"/3g_check_status.sh
connect="$DIR"/3g_connect.sh
disconnect="$DIR"/3g_disconnect.sh
report_rxtx="$DIR"/3g_report_rxtx.sh
sakis3g="$DIR"/sakis3g

stick_vendor="1c9e"
stick_product="6061"
lsusb_grep_line="1c9e:6061 OMEGA TECHNOLOGY WL-72B 3.5G MODEM"

sakis_USBMODEM="${stick_vendor}:${stick_product}"
sakis_USBINTERFACE="0"
sakis_APN="gprs.swisscom.ch"

oscsend=/usr/local/bin/oscsend
osc_report_host=localhost
osc_report_port=9999

#whether or not to delete all sms on sim / stick on initialization
#0: disabled 1: enabled
delete_all_sms=0

#SMS reports (connected, disconnected, transfer stats, debit)
#if number is not valid (xxxx) no attempt to send will be made
destination_phone="+41xxxxxxxxx"

_3g_network_interface="ppp0"

#sakis3g won't restore pre-connect default gw
post_add_route="route add default gw 10.10.10.1 p1p1"

#files
gammu_allsms=/tmp/gammu_allsms.txt

#before sakis3g connect
#i.e. killall -9 <tool>
pre_connect_cmd="sleep 0.1"

#i.e. startup <tool>
post_connect_cmd="sleep 0.1"

#i.e. killall -9 <tool>
pre_disconnect_cmd="sleep 0.1"

function checkAvail()
{
	which "$1" >/dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]
	then
		echo "tool \"$1\" not found. please install"
		exit 1
	fi
}
