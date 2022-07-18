function Enable-VRisingServerMonitor {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer[]] $Server
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            $servers = [VRisingServer]::FindServers($ShortName)
        } else {
            $servers = $Server
        }
        foreach ($serverItem in $servers) {
            try {
                $serverItem.Enable()
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                continue
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Enable-VRisingServerMonitor -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
