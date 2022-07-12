# module parameters
$ErrorActionPreference = 'Stop'

$script:ModuleVersion = (Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'VRisingServerManager.psd1')).ModuleVersion
Write-Host "VRisingServerManager v$ModuleVersion"

if ($null -ne $VRisingServerManagerFlags) {
    $enabledFlags = $VRisingServerManagerFlags.GetEnumerator() | Where-Object { $_.Value -eq $true } | Select-Object -ExpandProperty Name
    if ($enabledFlags.Count -gt 0) {
        Write-Host "Using VRisingServerManagerFlags: $enabledFlags"
    }
} else {
    $VRisingServerManagerFlags = @{}
}
