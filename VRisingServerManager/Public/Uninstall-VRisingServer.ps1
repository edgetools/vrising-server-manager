using module ..\Class\ServiceProviderPort.psm1
using module ..\Class\ServiceProviderWindowsAdapter.psm1

function Uninstall-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter()]
        [ServiceProviderPort]
        $ServiceProvider = [ServiceProviderWindowsAdapter]::New()
    )

    $ServiceProvider.Uninstall()
}
