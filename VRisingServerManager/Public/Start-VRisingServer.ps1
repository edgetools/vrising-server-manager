function Start-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
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
