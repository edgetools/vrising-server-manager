function New-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $ShortName
    )

    [VRisingServer]::CreateServer($ShortName)
}
