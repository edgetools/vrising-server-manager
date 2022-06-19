function Update-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            try {
                [VRisingServer]::DoServers('Update', $null, $ShortName)
            } catch [System.AggregateException] {
                $_.Exception.InnerExceptions | ForEach-Object { Write-Error $_ }
                return
            }
        } else {
            try {
                $Server.Update()
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                return
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Update-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
