class ServiceProviderPort {
    # start the service
    [void] Start([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
    }

    # stop the service
    [void] Stop([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
    }

    # set the service to automatically start
    [void] Enable([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
    }

    # prevent the service from automatically starting
    [void] Disable([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
    }

    # create the service entry
    [void] Install([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
    }

    # remove the service entry
    [void] Uninstall([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
    }

    # is service currently running
    [bool] IsRunning([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
        return $null
    }

    # is service currently installed
    [bool] IsInstalled([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
        return $null
    }

    # is service set to automatically start
    [bool] IsEnabled([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
        return $null
    }
}
