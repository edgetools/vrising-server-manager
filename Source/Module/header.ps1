# module parameters
$ErrorActionPreference = 'Stop'

$script:ModuleVersion = (Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'VRisingServerManager.psd1')).ModuleVersion
Write-Host "VRisingServerManager v$ModuleVersion"

if ($false -eq [string]::IsNullOrEmpty($VRisingServerManagerFlags)){
    Write-Host "Using VRisingServerManagerFlags: $VRisingServerManagerFlags"
}
