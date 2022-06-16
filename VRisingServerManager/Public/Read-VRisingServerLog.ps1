using module ..\Class\VRisingServer.psm1

function Read-VRisingServerLog {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param(
        [Parameter(Position=1, ParameterSetName='ByShortName')]
        [Parameter(Position=1, ParameterSetName='ByServer')]
        [VRisingServerLogType] $LogType = [VRisingServerLogType]::File,

        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server,

        [Parameter()]
        [int]$Last
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            [VRisingServer]::ReadServerLogType($ShortName, $LogType, $Last)
        } else {
            $Server.ReadLogType($LogType, $Last)
        }
    }
}

Register-ArgumentCompleter -CommandName Read-VRisingServerLog -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
