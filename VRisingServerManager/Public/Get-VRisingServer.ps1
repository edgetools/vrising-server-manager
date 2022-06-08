using module ..\Class\VRisingServer.psm1
using module ..\Class\VRisingServerRepository.psm1

function Get-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true)]
        [string[]] $Name,

        [Parameter()]
        [VRisingServerRepository] $ServerRepository
    )

    # get default repository if unspecified
    if ($null -eq $ServerRepository) {
        $ServerRepository = Get-VRisingServerRepository
    }
    # throw if still null
    if ($null -eq $ServerRepository) {
        throw [System.ArgumentNullException]::New("ServerRepository")
    }

    # TODO: default server can be a list of servers (Get-VRisingServer pub* | Set-VRisingActiveServers)
    [string[]] $serverNames = $ServerRepository.GetNames($Name)
    [VRisingServer[]] $servers = $ServerRepository.Load($serverNames)

    return $servers
}

Register-ArgumentCompleter -CommandName Get-VRisingServer -ParameterName Name -ScriptBlock $function:ServerNameArgumentCompleter
