ExportAliases

$Global:PSDefaultParameterValues['Start-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Stop-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Update-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Remove-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Enable-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Disable-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Restart-VRisingServer:ErrorAction'] = 'Continue'

# custom formatters
Update-FormatData -AppendPath "$PSScriptRoot\VRisingServerManager.Format.ps1xml"
