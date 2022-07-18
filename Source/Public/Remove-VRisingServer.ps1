function Remove-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName', SupportsShouldProcess, ConfirmImpact='High')]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer[]] $Server,

        [Parameter()]
        [switch] $Force
    )

    process {
        if ($Force){
            $ConfirmPreference = 'None'
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            $servers = [VRisingServer]::FindServers($ShortName)
        } else {
            $servers = $Server
        }
        foreach ($serverItem in $servers) {
            try {
                if ($true -eq $PSCmdlet.ShouldProcess($serverItem.ShortName)) {
                    [VRisingServer]::DeleteServer($serverItem, $Force)
                }
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                continue
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
