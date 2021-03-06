function ExportAliases {
    $commandAliases = @{
        vrget = 'Get-VRisingServer'
        vrcreate = 'New-VRisingServer'
        vrdelete = 'Remove-VRisingServer'
        vrmget = 'Get-VRisingServerManagerConfigOption'
        vrmset = 'Set-VRisingServerManagerConfigOption'
        vrstart = 'Start-VRisingServer'
        vrstop = 'Stop-VRisingServer'
        vrupdate = 'Update-VRisingServer'
        vrlog = 'Read-VRisingServerLog'
        vrenable = 'Enable-VRisingServerMonitor'
        vrdisable = 'Disable-VRisingServerMonitor'
        vrrestart = 'Restart-VRisingServer'
        vrset = 'Set-VRisingServer'
    }
    foreach ($commandAlias in $commandAliases.GetEnumerator()) {
        New-Alias -Value $commandAlias.Value -Name $commandAlias.Key -Scope Script
    }
}
