using module ..\Class\VRisingServer.psm1

function New-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $ShortName
    )

    [VRisingServer]::CreateServer($ShortName)
}
