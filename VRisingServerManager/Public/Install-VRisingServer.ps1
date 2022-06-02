using module ..\Class\ServiceProviderPort.psm1
using module ..\Class\ServiceProviderWindowsAdapter.psm1

function Install-VRisingServer {
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

    $ServiceProvider.Install()
}
