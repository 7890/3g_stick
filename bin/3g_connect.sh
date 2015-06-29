#!/bin/bash

#part of https://github.com/7890/3g_stick
#//tb/1506

#in /etc/usb_modeswitch.conf:
#DisableSwitching=1

#in ~/.gammurc:
#adjust port to /dev/ttyUSB2
#-> send/receive sms while gprs connection established

#to connect at system startup:
#in /etc/rc.local:
#screen -d -m -S osclog /usr/local/bin/oscdump 9999
#/path/to/3g_stick/bin/3g_connect.sh >> /tmp/3g_connect.log 2>&1 &

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/3g_config.sh

for tool in {"$sakis3g","$oscsend","$report_rxtx",lsusb,rmmod,eject,usb_modeswitch,modprobe,gammu,sed,cut,dmesg,ifconfig,id,egrep}; \
	do checkAvail "$tool"; done

#check if script is started as root or sudo
user_id=`id -u`
if [ x"$user_id" != "x0" ]
then
	echo "run script as user root or with sudo."
	exit 1
fi

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
#usb_modeswitch -W -v "$stick_vendor" -p "$stick_product"
sleep 1
modprobe option
echo "$stick_vendor $stick_product" > /sys/bus/usb-serial/drivers/option1/new_id
sleep 8

echo "dmesg output"
echo "============"

dmesg | tail -20

if [ x"$delete_all_sms" = "x1" ]
then

	#$ gammu getsmsfolders
	#1. "  Inbox", SIM memory, Inbox folder
	#2. " Outbox", SIM memory, Outbox folder
	#3. "  Inbox", phone memory, Inbox folder
	#4. " Outbox", phone memory, Outbox folder

	echo "deleting SMS on device"
	echo "======================"
	gammu deleteallsms 1
	gammu deleteallsms 2
	gammu deleteallsms 3
	gammu deleteallsms 4
else
	echo "keeping all SMS"
fi

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

	#+xxyyzzzzzzz
	phone=`echo "$destination_phone" | egrep -o "+[[:digit:]]{11,11}"`
	ret=$?

	if [ x"$ret" = "x0" ]
	then
		echo "notifiying connection success to $destination_phone"
		echo "==================================================="
		echo -e "GPRS Verbindung aufgebaut.\n`date`" | gammu sendsms TEXT "$destination_phone"
	else
		echo "phone number for sms notification not valid"
	fi

else
	$oscsend $osc_report_host $osc_report_port /gprs/connection_setup/error
fi

ifconfig "${_3g_network_interface}"
