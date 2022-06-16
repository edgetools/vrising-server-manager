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
            [VRisingServer]::StopServers($ShortName, $Force)
        } else {
            $Server.Stop($Force)
        }
    }
}

Register-ArgumentCompleter -CommandName Stop-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
