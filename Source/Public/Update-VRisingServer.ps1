function Update-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName', SupportsShouldProcess)]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer[]] $Server,

        [Parameter()]
        [switch] $Queue
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
                    $serverItem.Update($Queue)
                }
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                continue
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Update-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
