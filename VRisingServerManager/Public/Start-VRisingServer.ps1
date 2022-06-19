function Start-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            try {
                [VRisingServer]::DoServers('Start', $null, $ShortName)
            } catch [System.AggregateException] {
                $_.Exception.InnerExceptions | ForEach-Object { Write-Error $_ }
                return
            }
        } else {
            try {
                $Server.Start()
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                return
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Start-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
