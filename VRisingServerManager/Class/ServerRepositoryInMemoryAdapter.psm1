using module .\ServerRepositoryPort.psm1
using module .\VRisingServer.psm1

class ServerRepositoryInMemoryAdapter : ServerRepositoryPort {
    [hashtable] $Servers = @{}

    [VRisingServer] Load([string]$Name) {
        $server = [VRisingServer]::New()
        $server.Name = $this.Servers[$Name].Name
        $server.UpdateOnStartup = $this.Servers[$Name].UpdateOnStartup
        $server.ServiceName = $this.Servers[$Name].ServiceName
        return $server
    }

    [void] Save([VRisingServer]$Server) {
        $this.Servers[$Server.Name] = @{
            Name = $Server.Name
            UpdateOnStartup = $Server.UpdateOnStartup
            ServiceName = $Server.ServiceName
        }
    }
}
