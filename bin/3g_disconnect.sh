#!/bin/bash

#part of https://github.com/7890/3g_stick
#//tb/1506

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/3g_config.sh

for tool in {"$sakis3g","$oscsend",sed,gammu,killall,id,egrep}; \
	do checkAvail "$tool"; done

#check if script is started as root or sudo
user_id=`id -u`
if [ x"$user_id" != "x0" ]
then
	echo "run script as user root or with sudo."
	exit 1
fi

echo "disconnecting sakis3g connection"
echo "================================"

#save rx/tx from ppp0
rx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "RX bytes" | cut -d ":" -f2 | cut -d" " -f1`
tx_bytes=`/sbin/ifconfig -a | grep -A6 "${_3g_network_interface}" | grep "TX bytes" | cut -d ":" -f3 | cut -d" " -f1`

#stop reporting
killall -9 3g_report_rxtx.sh

eval "$pre_disconnect_cmd"

#disconnect gprs
$sakis3g --sudo "disconnect" --console USBMODEM="$sakis_USBMODEM" USBINTERFACE="$sakis_USBINTERFACE" APN="$sakis_APN"

ret=$?
echo $ret

$oscsend $osc_report_host $osc_report_port /gprs/disconnected

#restore default route
$post_add_route

sleep 1

echo "requesting service status"
echo "========================="

#migros m-budget mobile
echo "STATUS" | gammu sendsms TEXT 444
rm -f "$gammu_allsms"

#wait for sms to arrive
sleep 10

echo "retrieving SMS from device"
echo "=========================="
gammu getallsms > "$gammu_allsms"

#custom text parsing to get prepaid status (available transfer volume, debit)
balance=`cat "$gammu_allsms" | grep -B2 -A5 ' : "444"' | grep -A5 "UnRead" \
	| grep "Sie haben insgesamt noch " \
	| sed 's/Sie haben insgesamt noch //g' \
	| sed 's/ für den nationalen Datenverkehr zur Verfügung. Ihr Guthaben beträgt zurzeit /, /'`

#105,96 MB 113,3  CHF. (Stand vom 28.06.2015)

$oscsend $osc_report_host $osc_report_port /gprs/rxtx ii $rx_bytes $tx_bytes

#+xxyyzzzzzzz
phone=`echo "$destination_phone" | egrep -o "+[[:digit:]]{11,11}"`
ret=$?

if [ x"$ret" = "x0" ]
then
	echo "sending status SMS to $destination_phone"
	echo "=================================="

	echo -e "GPRS Verbindung getrennt.\nRX: $rx_bytes\nTX: $tx_bytes\n`date`\nVerfügbar: $balance" \
		| gammu sendsms TEXT "$destination_phone"
else
	echo "phone number for sms notification not valid"
fi

$oscsend $osc_report_host $osc_report_port /gprs/status s "$balance"
