class VRisingServerProcessMonitor {
    hidden [VRisingServer] $_server

    VRisingServerProcessMonitor([VRisingServer]$server) {
        $this._server = $server
    }

    [void] Run() {
        $runLoop = $true
        while ($true -eq $runLoop) {
            $properties = $this._server.ReadProperties('RunProcessMonitor')
            if ($false -eq $properties.RunProcessMonitor) {
                $runLoop = $false
            }
            Write-Host 'ServerMonitor is Running...'
            Start-Sleep -Seconds 1
        }
    }
}
