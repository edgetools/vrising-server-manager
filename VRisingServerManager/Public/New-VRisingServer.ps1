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

    # check for existing config file and service
    $ServerConfigFilePath = Join-Path -Path $ServerConfigDirPath -ChildPath "$ShortName.json"
    if (Test-Path -LiteralPath $ServerConfigFilePath -PathType Leaf) {
        throw "Server '$ShortName' already exists"
    }
    $ServiceName = "V Rising Server ($ShortName)"
    if (ServiceIsInstalled $ServiceName) {
        throw "Service '$ServiceName' already exists"
    }

    # # ensure server config dir exists
    # if (-Not (Test-Path -LiteralPath $ServerConfigDirPath -PathType Container)) {
    #     $ServerConfigDir = New-Item -Path $ServerConfigDirPath -ItemType Directory -ErrorAction Stop
    # }

    # create the service
    Install-VRisingServerService -ServiceName $ServiceName -ErrorAction Stop

    # save the config file
    $ServerConfigFile = @{
        ShortName = $ShortName
        UpdateOnStartup = $UpdateOnStartup
        ServiceName = $ServiceName
    }
    $ServerConfigFile | ConvertTo-Json -ErrorAction Stop | Out-File -LiteralPath $ServerConfigFilePath
}
