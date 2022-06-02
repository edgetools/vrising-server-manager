using module ..\Class\ServerRepositoryPort.psm1
using module ..\Class\ServerRepositoryFileAdapter.psm1
using module ..\Class\ServiceProviderPort.psm1
using module ..\Class\ServiceProviderWindowsAdapter.psm1

function Enable-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter()]
        [ServerRepositoryPort]
        $ServerRepository = [ServerRepositoryFileAdapter]::New(),

        [Parameter()]
        [ServiceProviderPort]
        $ServiceProvider = [ServiceProviderWindowsAdapter]::New()
    )

    $ServiceProvider.Enable()
}
