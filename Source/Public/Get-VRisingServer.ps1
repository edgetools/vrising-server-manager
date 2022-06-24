function Get-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string[]] $ShortName,

        [Parameter(Position=1)]
        [VRisingServerSettingsType] $SettingsType,

        [Parameter(Position=2)]
        [string] $SettingName
    )

    if ($null -ne $SettingsType) {
        $servers = [VRisingServer]::FindServers($ShortName)
        foreach ($server in $servers) {
            switch ($SettingsType) {
                ([VRisingServerSettingsType]::Host) {
                    $server.GetHostSetting($SettingName)
                }
                ([VRisingServerSettingsType]::Game) {
                    $server.GetGameSetting($SettingName)
                }
                ([VRisingServerSettingsType]::Voip) {
                    $server.GetVoipSetting($SettingName)
                }
            }
        }
    } else {
        return [VRisingServer]::FindServers($ShortName)
    }
}

Register-ArgumentCompleter -CommandName Get-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter

Register-ArgumentCompleter -CommandName Get-VRisingServer -ParameterName SettingName -ScriptBlock $function:ServerSettingsFileArgumentCompleter