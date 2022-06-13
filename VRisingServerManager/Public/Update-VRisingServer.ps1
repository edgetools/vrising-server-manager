function Update-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            [VRisingServer]::UpdateServers($ShortName)
        } else {
            $Server.Update()
        }
    }
}

Register-ArgumentCompleter -CommandName Update-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
