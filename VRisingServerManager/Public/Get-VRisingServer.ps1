using module ..\Class\ServerRepositoryFileAdapter.psm1
using module ..\Class\ServiceProviderWindowsAdapter.psm1

function Get-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepositoryDirPath = $script:DefaultServerRepositoryDirPath
    )

    $FileServerRepository = [ServerRepositoryFileAdapter]::New($RepositoryDirPath)
    $WindowsServiceProvider = [ServiceProviderWindowsAdapter]::New()

    return GetServer `
        -Name $Name `
        -ServerRepository $FileServerRepository `
        -ServiceProvider $WindowsServiceProvider
}
