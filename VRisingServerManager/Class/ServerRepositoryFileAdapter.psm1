using module .\ServerRepositoryPort.psm1
using module .\VRisingServer.psm1

class ServerRepositoryFileAdapter : ServerRepositoryPort {
    [string] $ConfigDirPath

    ServerRepositoryFileAdapter([string]$ConfigDirPath) {
        $this.ConfigDirPath =  $ConfigDirPath
    }

    [VRisingServer] Load([string]$Name) {
        $ServerFilePath = "$($this.ConfigDirPath)\$Name.json"
        if (Test-Path -LiteralPath $ServerFilePath -PathType Leaf) {
            $ServerFile = Get-Content -LiteralPath $ServerFilePath | ConvertFrom-Json
            $Server = [VRisingServer]::New()
            $Server.Name = $ServerFile.Name
            $Server.UpdateOnStartup = $ServerFile.UpdateOnStartup
            return $Server
        } else {
            return $null
        }
    }
}
