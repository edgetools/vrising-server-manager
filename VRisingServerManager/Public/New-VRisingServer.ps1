using module ..\Class\VRisingServerRepository.psm1
using module ..\Class\VRisingServer.psm1

function New-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[0-9A-Za-z]+$')]
        [string] $ShortName,

        [Parameter()]
        [bool] $UpdateOnStartup = $true,

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

    # check for existing server in repository
    if ($ServerRepository.Contains($ShortName)) {
        throw "Server '$ShortName' already exists"
    }

    # create the new server
    $server = [VRisingServer]::New()
    $server.Name = $ShortName
    $server.UpdateOnStartup = $UpdateOnStartup

    # save the new server
    $ServerRepository.Save($server)
}
