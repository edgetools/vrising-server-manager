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
            [VRisingServer]::StartServers($ShortName)
        } else {
            $Server.Start()
        }
    }
}

Register-ArgumentCompleter -CommandName Start-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
