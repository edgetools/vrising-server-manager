function Enable-VRisingServer {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            [VRisingServer]::EnableServers($ShortName)
        } else {
            $Server.Enable()
        }
    }
}

Register-ArgumentCompleter -CommandName Enable-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
