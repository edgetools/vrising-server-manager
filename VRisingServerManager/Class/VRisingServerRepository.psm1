using module .\VRisingServer.psm1

class VRisingServerRepository {
    [string] $DirPath

    VRisingServerRepository([string]$dirPath) {
        $this.DirPath = $dirPath
    }

    [void] Save([VRisingServer]$server) {}

    [VRisingServer] Load([string]$name) {
        $serverConfigFilePath = Join-Path -Path $this.DirPath -ChildPath "$name.json" -ErrorAction Stop
        try {
            $serverConfigFile = Get-Content -LiteralPath $serverConfigFilePath -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            $_.ErrorDetails = "Server '$name' not found"
            throw $_
        }
        $serverConfig = $serverConfigFile | ConvertFrom-Json -ErrorAction Stop
        $server = [VRisingServer]::New()
        $server.Name = $serverConfig.Name
        $server.UpdateOnStartup = $serverConfig.UpdateOnStartup
        return $server
    }

    [string[]] GetNames([string]$namePrefix) {
        $searchPath = Join-Path -Path $this.DirPath -ChildPath "$namePrefix*.json" -ErrorAction Stop
        $configFiles = Get-ChildItem -Path "$($this.DirPath)\$namePrefix*.json" -File
        $serverNames = $configFiles | Select-Object -ExpandProperty BaseName -ErrorAction Stop
        return $serverNames
    }

    [bool] Exists() {
        return Test-Path -LiteralPath $this.DirPath -PathType Container -ErrorAction Stop
    }

    [bool] Contains([string]$name) {
        $serverConfigFilePath = Join-Path -Path $this.DirPath -ChildPath "$name.json" -ErrorAction Stop
        return Test-Path -LiteralPath $serverConfigFilePath -PathType Leaf -ErrorAction Stop
    }
}
