#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILE=/tmp/smart_status
CHECK_SMART_OVERRIDE="Reallocated_Sector_Ct=40,Reallocated_Event_Count=40,Current_Pending_Sector=10,Runtime_Bad_Block=1000,Command_Timeout=1000,Reported_Uncorrect=40,Offline_Uncorrectable=40"
CHECK_SMART_EXCLUDE="Command_Timeout,Airflow_Temperature_Cel"
CHECK_SMART_SCRIPT="$CWD/check_smart.pl" # https://www.claudiokuenzler.com/monitoring-plugins/check_smart.php

if [ ! -f /usr/sbin/smartctl ]; then
        echo "No se encuentra smartctl. Abortando."
        exit 1
fi

wget -q https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/check_smart.pl -O $CWD/check_smart.pl
chmod 755 $CWD/check_smart.pl

MESSAGE="OK"

rm -f $FILE
touch $FILE

function enable_smart() { # $1: disk
	# CHEQUEO SI ESTA DESACTIVADO SI NO LO ACTIVO
	if smartctl -i $1 | grep -E ".*SMART.*Disabled" > /dev/null; then
		echo "SMART deshabilitado en $1. Habilitando..." >> $FILE
		smartctl -s on $1 2>&1 > /dev/null
	fi
}

if test $(find /usr/share/smartmontools/drivedb.h -mtime +60); then
	# Updateando base de datos SMART
	echo "Actualizando la base de SMART..."
	update-smart-drivedb 2>&1 > /dev/null
	update-smart-drivedb --no-verify 2>&1 > /dev/null # HAY VECES QUE EL CERTIFICADO SE ACTUALIZA Y NO PUEDE VERIFICARLO
fi

# SI TIENE MEGARAID CHEQUEO SMART ATRAS DE LA CONTROLADORA https://piyecarane.wordpress.com/2014/02/01/monitoring-physical-disk-with-smart-under-lsi-2108/
if lspci | grep -i megaraid > /dev/null; then
	wget -q https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/bin/MegaCli/MegaCli64 -O /var/MegaCli64; chmod 755 /var/MegaCli64	
	/var/MegaCli64 -pdlist -a0 | grep "Device Id" | awk '{ print $3 }' | sort | while read MEGAID
	do
		$CHECK_SMART_SCRIPT -g "/dev/sda" -i "megaraid,$MEGAID" -w "$CHECK_SMART_OVERRIDE" -e "$CHECK_SMART_EXCLUDE" >> $FILE 2>&1 # PARA MEGARAID (a /dev/sda no le da bola pero hay que poner algo)
	done
	rm -f /var/MegaCli64

	for devfull in /dev/sd?; do
		enable_smart $devfull
        	$CHECK_SMART_SCRIPT -d "$devfull" -i auto -w "$CHECK_SMART_OVERRIDE" -e "$CHECK_SMART_EXCLUDE" | grep -v "UNKNOWN" >> $FILE 2>&1 # PARA LOS DEMAS DISCOS
	done

else
	# PARA TODOS LOS DISCOS (incluidos los que están atrás de otras controladoras RAID no-megaraid)
	for devfull in /dev/sg? /dev/sd?; do
		enable_smart $devfull
		$CHECK_SMART_SCRIPT -d "$devfull" -i auto -w "$CHECK_SMART_OVERRIDE" -e "$CHECK_SMART_EXCLUDE" | grep -v "UNKNOWN" >> $FILE 2>&1
	done

fi

# CAMBIO WARNING POR ERROR
sed -i 's/WARNING/ERROR/g' $FILE
cat $FILE | sort | uniq

rm -f $FILE
rm -f $CWD/check_smart.pl

exit 0

