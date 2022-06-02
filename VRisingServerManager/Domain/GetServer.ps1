using module ..\Class\ServerRepositoryPort.psm1
using module ..\Class\ServiceProviderPort.psm1

function GetServer() {
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory=$True)]
        [ValidateNotNull()]
        [ServerRepositoryPort]
        $ServerRepository,

        [Parameter(Mandatory=$True)]
        [ValidateNotNull()]
        [ServiceProviderPort]
        $ServiceProvider
    )

    $Server = $ServerRepository.Load($Name)

    return $Server
}
