using module ..\Class\ServiceProviderPort.psm1

function DisableService() {
    param(
        [Parameter()]
        [ServiceProviderPort]
        $ServiceProvider
    )

    if ($ServiceProvider.IsEnabled()) {
        $ServiceProvider.Disable()
    }
}
