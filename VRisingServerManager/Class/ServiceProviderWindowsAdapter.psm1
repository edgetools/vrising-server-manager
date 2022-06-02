using module .\ServiceProviderPort.psm1

class ServiceProviderWindowsAdapter : ServiceProviderPort {
    [bool] IsInstalled([string]$Name) {
        try {
            Get-Service -Name $Name -ErrorAction Stop
            return $True
        }
        catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
            if (($_.FullyQualifiedErrorId -Split ',')[0] -ne 'NoServiceFoundForGivenName') {
                throw
            }
            return $False
        }
    }

    [void] Install([string]$Name) {
        New-Service -Name $Name -BinaryPathName '"powershell.exe -Command { while ($True) { Start-Sleep -Seconds 1; } }"' -ErrorAction Stop
    }

    [void] Uninstall([string]$Name) {
        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$Name'"
        if ($null -ne $service) {
            $service.delete()
        }
    }
}
