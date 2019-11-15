# CheckHardware
Conjunto de script para chequeo de Hardware.
Chequea:

 - Estado de SMART de los discos
 - Estado de los volúmenes RAID (si tiene placa RAID)
 - Cantidad de memoria RAM disponible
 - Espacio en disco disponible

## Ejecución
### Windows
Ejecutar en PowerShell:

    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wnpower/CheckHardware/master/windows/hw_report.ps1" -OutFile "$pwd/hw_report.ps1"; Set-ExecutionPolicy RemoteSigned -Force; & "$pwd/hw_report.ps1"; Remove-Item "$pwd/hw_report.ps1"

### Linux
TODO
