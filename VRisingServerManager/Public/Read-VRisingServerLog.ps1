using module ..\Class\VRisingServer.psm1

function Read-VRisingServerLog {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server,

        [Parameter(Position=1, ParameterSetName='ByShortName')]
        [Parameter(ParameterSetName='ByServer')]
        [VRisingServerLogType] $LogType = [VRisingServerLogType]::File
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            [VRisingServer]::ReadServerLogType($ShortName, $LogType)
        } else {
            $Server.ReadLogType($LogType)
        }
    }
}

Register-ArgumentCompleter -CommandName Read-VRisingServerLog -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
