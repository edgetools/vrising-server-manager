using module ..\Class\ServiceProviderPort.psm1

function EnableService() {
    param(
        [Parameter()]
        [ServiceProviderPort]
        $ServiceProvider
    )

    if (-Not $ServiceProvider.IsEnabled()) {
        $ServiceProvider.Enable()
    }
}
