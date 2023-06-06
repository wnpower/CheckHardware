#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# CHECK ESPACIO EN DISCO
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
		$CWD/bin/sas2ircu 0 STATUS | grep "Optimal" > /dev/null && echo "SAS2008|SAS2004: OK" || echo "SAS2008|SAS2004: ERROR"

        elif echo "$RAID" | grep "SAS1064\|SAS1068" > /dev/null; then
		echo -ne "1\n21\n1" | $CWD/bin/lsiutil.1.71.x86_64 2>/dev/null | grep "optimal" >/dev/null && echo "SAS1064|SAS1068: OK" || echo "SAS1064|SAS1068: ERROR"

        elif echo "$RAID" | grep "M1015\|SAS 2108\|SAS2108\|SAS9260\|3108" > /dev/null; then
        	$CWD/bin/storcli64 /c0 show | grep "VD LIST" -A10 | grep "RAID" | grep -v "Optl" > /dev/null && echo "M1015|SAS2108|SAS9260|3108: ERROR" || echo "M1015|SAS2108|SAS9260|3108: OK"
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

# CHECK DE LOGS
# MESSAGES
echo "Errores en /var/log/messages:"
echo ""
tail -n 10000 /var/log/messages | grep -av Firewall | grep -av named | grep -av pure | grep -av crond | grep -av snmpd | grep -av repeated | grep -av "nscd:" | grep -avi "sssd" | grep -av "systemd: Started" | grep -av "systemd: Starting" | grep -av "systemd: Removed slice" | grep -av "systemd: Created slice" | grep -av "systemd: Stopping" | grep -av "freedesktop" | grep -av "dhclient"

echo ""
echo "------------------------------------------------"
echo ""
