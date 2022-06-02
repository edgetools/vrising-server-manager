using module .\VRisingServer.psm1

class ServerRepositoryPort {
    # save server
    [void] Save([VRisingServer]$Server) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
    }
    # load server
    [VRisingServer] Load([string]$Name) {
        Write-Error -Exception ([System.NotImplementedException]::new()) -ErrorAction Stop
        return $null
    }
}
