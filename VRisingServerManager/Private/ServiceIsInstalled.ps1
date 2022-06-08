function ServiceIsInstalled([string]$Name) {
    try {
        Get-Service -Name $Name | Out-Null
        return $True
    }
    catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
        if (($_.FullyQualifiedErrorId -Split ',')[0] -ne 'NoServiceFoundForGivenName') {
            throw
        }
        return $False
    }
}
