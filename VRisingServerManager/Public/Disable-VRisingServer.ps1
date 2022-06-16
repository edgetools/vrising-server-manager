function Disable-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            [VRisingServer]::DisableServers($ShortName)
        } else {
            $Server.Disable()
        }
    }
}

Register-ArgumentCompleter -CommandName Disable-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
