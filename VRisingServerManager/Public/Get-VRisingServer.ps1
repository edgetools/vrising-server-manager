using module ..\Class\VRisingServer.psm1

function Get-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string[]] $ShortName
    )

    return [VRisingServer]::FindServers($ShortName)
}

Register-ArgumentCompleter -CommandName Get-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
