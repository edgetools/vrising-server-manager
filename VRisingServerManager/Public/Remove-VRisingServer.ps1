using module ..\Class\VRisingServer.psm1

function Remove-VRisingServer {
    [CmdletBinding()]
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
            [VRisingServer]::DeleteServers($ShortName, $Force)
        } else {
            [VRisingServer]::DeleteServer($Server, $Force)
        }
    }
}

Register-ArgumentCompleter -CommandName Remove-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
