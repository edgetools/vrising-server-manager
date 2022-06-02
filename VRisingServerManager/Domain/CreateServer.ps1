using module ..\Class\ServerRepositoryPort.psm1
using module ..\Class\ServiceProviderPort.psm1
using module ..\Class\VRisingServer.psm1

function CreateServer {
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServerName,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,

        [Parameter(Mandatory=$True)]
        [ValidateNotNull()]
        [ServerRepositoryPort]
        $ServerRepository,

        [Parameter(Mandatory=$True)]
        [ValidateNotNull()]
        [ServiceProviderPort]
        $ServiceProvider
    )

    $Server = [VRisingServer]::New()
    $Server.Name = $ServerName
    $Server.ServiceName = $ServiceName
    $ServiceProvider.Install($ServiceName)
    $ServerRepository.Save($Server)
    return $Server
}
