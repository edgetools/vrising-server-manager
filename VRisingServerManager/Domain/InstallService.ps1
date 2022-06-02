using module ..\Class\ServiceProviderPort.psm1

function InstallService() {
    param(
        [Parameter()]
        [ServiceProviderPort]
        $ServiceProvider
    )

    if (-Not $ServiceProvider.IsInstalled()) {
        $ServiceProvider.Install()
    }
}
