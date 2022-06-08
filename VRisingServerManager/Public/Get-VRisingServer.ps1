using module ..\Class\VRisingServer.psm1
using module ..\Class\VRisingServerRepository.psm1

function Get-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string] $Name,

        [Parameter()]
        [VRisingServerRepository] $ServerRepository
    )
    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw [System.ArgumentNullException]::New("Name")
    }
    # get default repository if unspecified
    if ($null -eq $ServerRepository) {
        $ServerRepository = Get-VRisingServerRepository
    }
    # throw if still null
    if ($null -eq $ServerRepository) {
        throw [System.ArgumentNullException]::New("ServerRepository")
    }

    # $ServerConfigFilePath = Join-Path -Path $ServerConfigDirPath -ChildPath "$ShortName.json"

    # try {
    #     $ServerConfigFile = Get-Content -LiteralPath $ServerConfigFilePath
    # } catch [System.Management.Automation.ItemNotFoundException] {
    #     $_.ErrorDetails = "Server '$ShortName' not found"
    #     throw $_
    # }

    # $ServerConfig = $ServerConfigFile | ConvertFrom-Json

    # $Server = [VRisingServer]::New()
    # $Server.ShortName = $ServerConfig.ShortName
    # $Server.UpdateOnStartup = $ServerConfig.UpdateOnStartup

    $server = $ServerRepository.Load($Name)

    return $server
}

Register-ArgumentCompleter -CommandName Get-VRisingServer -ParameterName Name -ScriptBlock $function:ServerNameArgumentCompleter
