#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# RAM
echo ""
echo "RAM disponible:"
echo ""
free -m
echo ""
echo "------------------------------------------------"
echo ""

# CHECK ESPACIO EN DISCO
echo ""
echo "Espacio en disco:"
echo ""
df -h

echo ""
echo "------------------------------------------------"
echo ""

# CHECK HARDWARE RAID
RAID=$(lspci | grep "RAID\|SCSI" 2>/dev/null)
RAID_ENABLED=$(lspci | grep "RAID\|SCSI" 2>&1 >/dev/null && echo "SI" || echo "NO")
if [ "$RAID_ENABLED" = "SI" ]; then
        echo "Tiene RAID por HW, detectando modelo..."
        if echo "$RAID" | grep "SAS2008\|SAS2004\|SAS 2008" > /dev/null; then
		wget -q https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/bin/sas2ircu -O /var/sas2ircu; chmod 755 /var/sas2ircu
		/var/sas2ircu 0 STATUS | grep "Optimal" > /dev/null && echo "SAS2008|SAS2004: OK" || echo "SAS2008|SAS2004: ERROR"
		rm -f /var/sas2ircu

        elif echo "$RAID" | grep "SAS1064\|SAS1068" > /dev/null; then
		wget -q https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/bin/lsiutil.1.71.x86_64 -O /var/lsiutil.1.71.x86_64; chmod 755 /var/lsiutil.1.71.x86_64
		echo -ne "1\n21\n1" | /var/lsiutil.1.71.x86_64 2>/dev/null | grep "optimal" >/dev/null && echo "SAS1064|SAS1068: OK" || echo "SAS1064|SAS1068: ERROR"
		rm -f /var/lsiutil.1.71.x86_64

        elif echo "$RAID" | grep "M1015\|SAS 2108\|SAS2108\|SAS9260\|3108" > /dev/null; then
		wget -q https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/bin/storcli64 -O /var/storcli64; chmod 755 /var/storcli64
        	/var/storcli64 /c0 show | grep "VD LIST" -A10 | grep "RAID" | grep -v "Optl" > /dev/null && echo "M1015|SAS2108|SAS9260|3108: ERROR" || echo "M1015|SAS2108|SAS9260|3108: OK"
		rm -f /var/storcli64
	fi

fi

# CHECK SOFTWARE RAID
MDADM=$(mdadm --detail --scan 2> /dev/null)

if [ "$MDADM" != "" ]; then
	echo "Software RAID detectado"

	while read MD
	do
        	STATUS=$(mdadm --detail $MD | grep -i "State : .*degraded\|State: .*error\|State: .*fail" > /dev/null && echo "ERROR" || echo "OK")

	        if [ "$STATUS" = "ERROR" ]; then
        	        echo "$MD: ERROR - FAILED"
	        else
        	        echo "$MD: OK" >> $FILE
	        fi
	done <<< "$(ls -1 /dev/md* | grep "md[0-9]")"
fi

echo ""
echo "------------------------------------------------"
echo ""

# SMART
wget -q https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/check_smart.pl -O $CWD/check_smart.pl
wget -q https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/check_smart.pl -O $CWD/check_smart.sh
chmod 755 $CWD/check_smart.sh
chmod 755 $CWD/check_smart.pl

$CWD/check_smart.sh

rm -f $CWD/check_smart.pl
rm -f $CWD/check_smart.sh

# CHECK DE LOGS
# MESSAGES
echo "Errores en /var/log/messages:"
echo ""
tail -n 10000 /var/log/messages | grep -av Firewall | grep -av named | grep -av pure | grep -av crond | grep -av snmpd | grep -av repeated | grep -av "nscd:" | grep -avi "sssd" | grep -av "systemd: Started" | grep -av "systemd: Starting" | grep -av "systemd: Removed slice" | grep -av "systemd: Created slice" | grep -av "systemd: Stopping" | grep -av "freedesktop" | grep -av "dhclient"

echo ""
echo "------------------------------------------------"
echo ""
