#!/bin/bash

#part of https://github.com/7890/3g_stick
#//tb/1506

#in /etc/usb_modeswitch.conf:
#DisableSwitching=1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/3g_config.sh

for tool in {lsusb,rmmod,eject,usb_modeswitch,modprobe,gammu,sed,dmesg,ifconfig}; \
	do checkAvail "$tool"; done

cont=1
while [ $cont = 1 ]
do
	echo "looking for gsm stick..."
	echo "========================"
	lsusb | grep "$lsusb_grep_line"

	cont=$?
	sleep 2
done

echo "found gsm stick."
echo "================"

dmesg | tail -20

sleep 5

echo "setting up 3g stick"
echo "==================="

eject /dev/sr0
rmmod option
usb_modeswitch -W -v "$stick_vendor" -p "$stick_product"
sleep 1
modprobe option
sleep 1
echo "$stick_vendor $stick_product" > /sys/bus/usb-serial/drivers/option1/new_id
sleep 5

echo "dmesg output"
echo "============"

dmesg | tail -20

#$ gammu getsmsfolders
#1. "                         Inbox", SIM memory, Inbox folder
#2. "                        Outbox", SIM memory, Outbox folder
#3. "                         Inbox", phone memory, Inbox folder
#4. "                        Outbox", phone memory, Outbox folder

echo "deleting SMS on device"
echo "======================"
gammu deleteallsms 1
gammu deleteallsms 2
gammu deleteallsms 3
gammu deleteallsms 4

eval "$pre_connect_cmd"

echo "connecting with sakis3"
echo "======================"

$sakis3g --sudo "connect" USBMODEM="$sakis_USBMODEM" USBINTERFACE="$sakis_USBINTERFACE" APN="$sakis_APN"

ret=$?

echo $ret

if [ x"$ret" = "x0" ]
then
	$oscsend $osc_report_host $osc_report_port /gprs/connection_setup/success
	$report_rxtx &

	eval "$post_connect_cmd"

	echo "notifiying connection success to $destination_phone"
	echo "==================================================="
	echo -e "GPRS Verbindung aufgebaut.\n`date`" | gammu sendsms TEXT "$destination_phone"

else
	$oscsend $osc_report_host $osc_report_port /gprs/connection_setup/error
fi

ifconfig "${_3g_network_interface}"
