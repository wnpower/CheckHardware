# CheckHardware
Conjunto de script para chequeo de Hardware.
Chequea:

 - Estado de SMART de los discos
 - Estado de los volúmenes RAID (si tiene placa RAID)
 - Cantidad de memoria RAM y disco disponible
 - Espacio en disco disponible

## Ejecución
### Windows
Ejecutar en PowerShell:

	[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wnpower/CheckHardware/master/windows/hw_report.ps1" -OutFile "$pwd/hw_report.ps1"; Set-ExecutionPolicy RemoteSigned -Force; & "$pwd/hw_report.ps1"; Remove-Item "$pwd/hw_report.ps1"

### Linux
Ejecutar como root en consola SSH:

	wget https://raw.githubusercontent.com/wnpower/CheckHardware/master/linux/hw_report.sh; chmod 755 ./hw_report.sh; ./hw_report.sh
