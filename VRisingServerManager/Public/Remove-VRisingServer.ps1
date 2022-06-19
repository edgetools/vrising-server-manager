using module ..\Class\VRisingServer.psm1

function Remove-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server,

        [Parameter()]
        [switch] $Force
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            try {
                [VRisingServer]::DoServers('Delete', @($Force), $ShortName)
            } catch [System.AggregateException] {
                $_.Exception.InnerExceptions | ForEach-Object { Write-Error $_ }
                return
            }
        } else {
            try {
                [VRisingServer]::DeleteServer($Server, $Force)
            } catch [VRisingServerException] {
                Write-Error $_.Exception
                return
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
