using module ..\Class\VRisingServer.psm1

function Get-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string[]] $ShortName
    )

    # TODO: default server can be a list of servers (Get-VRisingServer pub* | Set-VRisingActiveServers)
    return [VRisingServer]::GetServers($ShortName)
}

Register-ArgumentCompleter -CommandName Get-VRisingServer -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
