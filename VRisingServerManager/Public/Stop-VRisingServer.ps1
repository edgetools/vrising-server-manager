function Stop-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server,

        [Parameter()]
        [switch] $Force
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            try {
                [VRisingServer]::DoServers('Stop', @($Force), $ShortName)
            } catch [System.AggregateException] {
                $_.Exception.InnerExceptions | ForEach-Object { Write-Error $_ }
                return
            }
        } else {
            try {
                $Server.Stop($Force)
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                return
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Stop-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
