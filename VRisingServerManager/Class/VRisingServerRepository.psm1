using module .\VRisingServer.psm1

class VRisingServerRepository {
    [string] $DirPath

    VRisingServerRepository([string]$dirPath) {
        $this.DirPath = $dirPath
    }

    [void] Save([VRisingServer]$server) {
        # ensure dir exists
        if (-Not (Test-Path -LiteralPath $this.DirPath -PathType Container)) {
            New-Item -Path $this.DirPath -ItemType Directory | Out-Null
        }
        # map to serializable object
        $serverData = @{
            Name = $server.Name
            UpdateOnStartup = $server.UpdateOnStartup
        }
        # convert to json and save to disk
        $serverData | ConvertTo-Json | Out-File -LiteralPath $this.GetPath($server.Name)
    }

    # loads of a list of servers by name
    [VRisingServer[]] Load([string[]]$names) {
        $servers = [System.Collections.ArrayList]::New()
        foreach ($name in $names) {
            $serverConfigFilePath = $this.GetPath($name)
            $serverConfigFile = Get-Content -LiteralPath $serverConfigFilePath
            $serverConfig = $serverConfigFile | ConvertFrom-Json
            $server = [VRisingServer]::New()
            $server.Name = $serverConfig.Name
            $server.UpdateOnStartup = $serverConfig.UpdateOnStartup
            $servers.Add($server)
        }
        return $servers.ToArray([VRisingServer])
    }

    # unwrap a list of keys
    [string[]] GetNames([string[]]$searchKeys) {
        $serverNames = [System.Collections.ArrayList]::New()
        # default wildcard if no key provided
        if ($null -eq $searchKeys) {
            $searchKeys = @('*')
        }
        foreach ($searchKey in $searchKeys) {
            $serversForKey = $this.GetNames($searchKey)
            if ($null -ne $serversForKey) {
                $serverNames.AddRange($serversForKey)
            }
        }
        $serverNamesArray = $serverNames.ToArray([string])
        return $serverNamesArray
    }

    # get all servers under a key
    [string[]] GetNames([string]$searchKey) {
        if (-Not (Test-Path -LiteralPath $this.DirPath -PathType Container)) {
            return [string]@()
        }
        # default wildcard if no key provided
        if ($null -eq $searchKey) {
            $searchKey = '*'
        }
        $searchPath = $this.GetPath($searchKey)
        $configFiles = Get-ChildItem -Path $searchPath -File
        [string[]] $serverNames = $configFiles | Select-Object -ExpandProperty BaseName
        return $serverNames
    }

    [bool] Contains([string]$name) {
        $serverConfigFilePath = $this.GetPath($name)
        return Test-Path -LiteralPath $serverConfigFilePath -PathType Leaf
    }

    # helper
    [string] hidden GetPath([string]$name) {
        return Join-Path -Path $this.DirPath -ChildPath "$name.json"
    }
}
