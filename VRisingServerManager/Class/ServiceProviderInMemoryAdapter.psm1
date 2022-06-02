using module .\ServiceProviderPort.psm1

class ServiceProviderInMemoryAdapter : ServiceProviderPort {
    [hashtable] $Services = @{}

    [bool] IsInstalled([string]$Name) {
        return $this.Services.ContainsKey($Name)
    }

    [bool] IsRunning([string]$Name) {
        return $this.Services[$Name].IsRunning
    }

    [bool] IsEnabled([string]$Name) {
        return $this.Services[$Name].IsEnabled
    }

    [void] Install([string]$Name) {
        $this.Services[$Name] = @{
            IsRunning = $false
            IsEnabled = $false
        }
    }

    [void] Uninstall([string]$Name) {
        $this.Services.Remove($Name)
    }

    [void] Start([string]$Name) {
        $this.Services[$Name].IsRunning = $true
    }

    [void] Stop([string]$Name) {
        $this.Services[$Name].IsRunning = $false
    }

    [void] Enable([string]$Name) {
        $this.Services[$Name].IsEnabled = $true
    }

    [void] Disable([string]$Name) {
        $this.Services[$Name].IsEnabled = $false
    }
}
