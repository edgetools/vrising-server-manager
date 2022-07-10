function New-VRisingServer {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true)]
        [string] $ShortName
    )

    if ($true -eq $PSCmdlet.ShouldProcess($ShortName)) {
        [VRisingServer]::CreateServer($ShortName)
    }
}
