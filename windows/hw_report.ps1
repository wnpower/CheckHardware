# INSTALL

if(!(Test-Path -Path $env:ChocolateyInstall)){
	echo "Instalando Chocolatey..."
	Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") # REFRESH PATH
}

if(!(Test-Path -Path 'C:\Program Files\smartmontools\bin\smartctl.exe')){
	echo "Instalando Smartmontools..."
	& $env:ChocolateyInstall\choco.exe install smartmontools -y
	refreshenv
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") # REFRESH PATH
}

echo ""
echo ""

# SMART
echo "SMART de los discos"
echo "-------------------"
echo ""
foreach ($drive in (Get-PSDrive -PSProvider FileSystem).Name)
{
	Write-Host -NoNewline "Revisando SMART de "$drive": ..."
	echo ""
	echo "--------------------------"
	$output = & 'C:\Program Files\smartmontools\bin\smartctl.exe' -a $drive":"
	$Reallocated_Sector_Ct = ((echo $output | Select-String -Pattern "Reallocated_Sector_Ct") -split " +")[10]
	$Reallocated_Event_Count = ((echo $output | Select-String -Pattern "Reallocated_Event_Count") -split " +")[10]
	$Current_Pending_Sector = ((echo $output | Select-String -Pattern "Current_Pending_Sector") -split " +")[10]
	
	if($Reallocated_Sector_Ct -And $Reallocated_Sector_Ct -gt 30) {
		echo "Reallocated_Sector_Ct: "$Reallocated_Sector_Ct" : CUIDADO"
	} else {
		echo "Reallocated_Sector_Ct - OK"
	}
	
	if($Reallocated_Event_Count -And $Reallocated_Event_Count -gt 30) {
		echo "Reallocated_Event_Count: "$Reallocated_Event_Count" : CUIDADO"
	} else {
		echo "Reallocated_Event_Count - OK"
	}
	
	if($Current_Pending_Sector -And $Current_Pending_Sector -gt 30) {
		echo "Current_Pending_Sector: "$Current_Pending_Sector" : CUIDADO"
	} else {
		echo "Current_Pending_Sector - OK"
	}
	
echo ""
}

# RAM

Function Test-MemoryUsage {
	[cmdletbinding()]
	Param()
 
	$os = Get-Ciminstance Win32_OperatingSystem
	$pctFree = [math]::Round(($os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,2)
 
	if ($pctFree -ge 45) {
		$Status = "OK"
	}
	elseif ($pctFree -ge 10 ) {
		$Status = "CUIDADO"
	}
	else {
		$Status = "CRITICO"
	}
 
	$os | Select @{Name = "Status";Expression = {$Status}},
	@{Name = "% Libre"; Expression = {$pctFree}},
	@{Name = "Libre GB";Expression = {[math]::Round($_.FreePhysicalMemory/1mb,2)}},
	@{Name = "Total GB";Expression = {[int]($_.TotalVisibleMemorySize/1mb)}} | Format-Table | Out-String
	
}

echo ""
echo ""
echo "Uso de memoria RAM"
echo "------------------"

Test-MemoryUsage

# ESPACIO DISCOS

echo "Uso de discos"
echo "-------------"
Get-PSDrive -PSProvider FileSystem | Format-Table | Out-String


# RAID
echo "RAID"
echo "-------------"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # FIX ERROR SSL
Get-WmiObject -Class Win32_SCSIController | foreach { $_.Name } | ForEach-Object -Process {
    switch -regex ($_) {
        '2004|2008' {
			"Detectado: $_"
			Invoke-WebRequest -Uri "https://github.com/wnpower/CheckHardware/raw/master/windows/bin/sas2ircu.exe" -OutFile "$pwd/sas2ircu.exe"
			& "$pwd\sas2ircu.exe" 0 STATUS | Select-String -Pattern "Volume state"
			Remove-Item "$pwd/sas2ircu.exe"
		}
        '3000|1064|1068' {
			"Detectado: $_"
			Invoke-WebRequest -Uri "https://github.com/wnpower/CheckHardware/raw/master/windows/bin/LSIUtil.exe" -OutFile "$pwd/LSIUtil.exe"
			echo "1`n21`n1" | & "$pwd\LSIUtil.exe" | Select-String -Pattern "Volume State:"
			Remove-Item "$pwd/LSIUtil.exe"
		}
        'MegaRAID' {
			"Detectado: $_"
			Invoke-WebRequest -Uri "https://github.com/wnpower/CheckHardware/raw/master/windows/bin/storcli.exe" -OutFile "$pwd/storcli.exe"
			& "$pwd\storcli.exe" show
			Remove-Item "$pwd/storcli.exe"
		}
    };
};

echo ""
echo "Errores en el Event Viewer (últimas 24 horas)"
echo "--------------------------"

echo ""
echo "Application"
echo "-----------"
echo ""
Get-EventLog application -After (Get-Date).AddHours(-24) | where {($_.EntryType -Match "Error") -and ($_.Source -NotMatch "Schannel") -or ($_.EntryType -Match "Critical")}

echo ""
echo "System"
echo "------"
echo ""
Get-EventLog system -After (Get-Date).AddHours(-24) | where {($_.EntryType -Match "Error") -and ($_.Source -NotMatch "Schannel") -or ($_.EntryType -Match "Critical")}
