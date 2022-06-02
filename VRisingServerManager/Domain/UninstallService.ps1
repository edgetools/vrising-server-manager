using module ..\Class\ServiceProviderPort.psm1

function UninstallService() {
    param(
        [Parameter()]
        [ServiceProviderPort]
        $ServiceProvider
    )

    if ($ServiceProvider.IsInstalled()) {
        $ServiceProvider.Uninstall()
    }
}
