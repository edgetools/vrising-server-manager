function Stop-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName', SupportsShouldProcess)]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer[]] $Server,

        [Parameter()]
        [switch] $Queue,

        [Parameter()]
        [switch] $Force
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            $servers = [VRisingServer]::FindServers($ShortName)
        } else {
            $servers = $Server
        }
        foreach ($serverItem in $servers) {
            try {
                if ($PSCmdlet.ShouldProcess($serverItem.ShortName)) {
                    $serverItem.Stop($Queue, $Force)
                }
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                continue
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Stop-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
