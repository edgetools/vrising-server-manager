function Set-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer')]
        [VRisingServer] $Server,

        [Parameter(Position=1)]
        [VRisingServerSettingsType] $SettingsType,

        [Parameter(Position=2)]
        [string] $SettingName,

        [Parameter(Position=3)]
        [psobject] $SettingValue,

        [Parameter()]
        [switch] $Default
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
        $servers = [VRisingServer]::FindServers($ShortName)
    } else {
        $servers = @($Server)
    }

    foreach ($server in $servers) {
        switch ($SettingsType) {
            ([VRisingServerSettingsType]::Host) {
                $server.SetHostSetting($SettingName, $SettingValue, $Default)
            }
            ([VRisingServerSettingsType]::Game) {
                $server.SetGameSetting($SettingName, $SettingValue, $Default)
            }
            ([VRisingServerSettingsType]::Voip) {
                $server.SetVoipSetting($SettingName, $SettingValue, $Default)
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Set-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter

Register-ArgumentCompleter -CommandName Set-VRisingServer -ParameterName SettingName -ScriptBlock $function:ServerSettingsFileArgumentCompleter

Register-ArgumentCompleter -CommandName Set-VRisingServer -ParameterName SettingValue -ScriptBlock $function:ServerSettingsFileArgumentCompleter
