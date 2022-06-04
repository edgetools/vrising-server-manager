using module .\ServerRepositoryPort.psm1
using module .\VRisingServer.psm1

class ServerRepositoryFileAdapter : ServerRepositoryPort {
    [string] $RepoDirPath

    ServerRepositoryFileAdapter([string]$RepoDirPath) {
        $this.RepoDirPath =  $RepoDirPath
    }

    [VRisingServer] Load([string]$Name) {
        if (Test-Path -LiteralPath $this.ServerFilePath($Name) -PathType Leaf) {
            $ServerFile = Get-Content -LiteralPath $this.ServerFilePath($Name) -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $Server = [VRisingServer]::New()
            $Server.Name = $ServerFile.Name
            $Server.UpdateOnStartup = $ServerFile.UpdateOnStartup
            return $Server
        } else {
            return $null
        }
    }

    [void] Save([VRisingServer]$Server) {
        $ServerFile = @{
            Name = $Server.Name
            UpdateOnStartup = $Server.UpdateOnStartup
            ServiceName = $Server.ServiceName
        }
        if (-Not (Test-Path -LiteralPath $this.RepoDirPath -PathType Container)) {
            New-Item -Path $this.RepoDirPath -ItemType Directory -ErrorAction Stop
        }
        $ServerFile | ConvertTo-Json -ErrorAction Stop | Out-File -LiteralPath $this.ServerFilePath() -ErrorAction Stop
    }

    hidden [string] ServerFilePath([string]$Name) {
        return "$($this.RepoDirPath)\$Name.json"
    }
}
