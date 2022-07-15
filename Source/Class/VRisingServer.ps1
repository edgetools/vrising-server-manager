class VRisingServer {
    # static variables
    static hidden [hashtable] $_config
    static hidden [string] $_configFilePath
    static hidden [string] $_serverFileDir
    static hidden [string] $DATA_DIR_NAME = 'Data'
    static hidden [string] $SAVES_DIR_NAME = 'Saves'
    static hidden [string] $INSTALL_DIR_NAME = 'Install'
    static hidden [string] $LOG_DIR_NAME = 'Log'

    # static constructor
    static VRisingServer() {
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName ShortName `
            -MemberType ScriptProperty `
            -Value { return $this._properties.ReadProperty('ShortName') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName SaveName `
            -MemberType ScriptProperty `
            -Value { return $this._settings.GetHostSetting('SaveName') } `
            -SecondValue { param($value) $this.SetHostSetting('SaveName',  $value) } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName DisplayName `
            -MemberType ScriptProperty `
            -Value { return $this._settings.GetHostSetting('Name') } `
            -SecondValue { param($value) $this.SetHostSetting('Name',  $value) } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName Status `
            -MemberType ScriptProperty `
            -Value { return $this._processMonitor.GetStatus() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName Monitor `
            -MemberType ScriptProperty `
            -Value { return $this._processMonitor.GetMonitorStatus() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName Command `
            -MemberType ScriptProperty `
            -Value { return $this._processMonitor.GetActiveCommand().Name } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName LastUpdate `
            -MemberType ScriptProperty `
            -Value { return $this._processMonitor.GetUpdateStatus() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName Uptime `
            -MemberType ScriptProperty `
            -Value { return $this._processMonitor.GetUptime() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName UpdateOnStartup `
            -MemberType ScriptProperty `
            -Value { return $this._properties.ReadProperty('UpdateOnStartup') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName InstallDir `
            -MemberType ScriptProperty `
            -Value { return $this._properties.ReadProperty('InstallDir') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName DataDir `
            -MemberType ScriptProperty `
            -Value { return $this._properties.ReadProperty('DataDir') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName SettingsDir `
            -MemberType ScriptProperty `
            -Value { return $this.GetSettingsDirPath() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName SavesDir `
            -MemberType ScriptProperty `
            -Value { return $this.GetSavesDirPath() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName LogDir `
            -MemberType ScriptProperty `
            -Value { return $this._properties.ReadProperty('LogDir') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName LogFile `
            -MemberType ScriptProperty `
            -Value { return $this._properties.GetLogFilePath([VRisingServerLogType]::Server) } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName FilePath `
            -MemberType ScriptProperty `
            -Value { return $this._filePath } `
            -Force
        [VRisingServer]::_configFilePath = Join-Path `
                -Path ([Environment]::GetEnvironmentVariable('ProgramData')) `
                -ChildPath 'edgetools' |
            Join-Path -ChildPath 'VRisingServerManager' |
            Join-Path -ChildPath 'config.json'
        [VRisingServer]::_serverFileDir = Join-Path `
                -Path ([Environment]::GetEnvironmentVariable('ProgramData')) `
                -ChildPath 'edgetools' |
            Join-Path -ChildPath 'VRisingServerManager' |
            Join-Path -ChildPath 'Servers'
        [VRisingServer]::_config = @{
            SkipNewVersionCheck = $false
            DefaultServerDir = 'D:\VRisingServers'
            SteamCmdPath = $null
        }
        [VRisingServer]::LoadConfigFile()
        if (($null -eq [VRisingServer]::_config['SteamCmdPath']) -or ($true -eq ([string]::IsNullOrWhiteSpace([VRisingServer]::_config['SteamCmdPath'])))) {
            [VRisingServerLog]::Warning("SteamCmdPath is unset -- resolve using: Set-VRisingServerManagerConfigOption SteamCmdPath 'path/to/steamcmd.exe'")
        }
    }

    static hidden [psobject[]] GetConfigValue([string]$configKey) {
        return [VRisingServer]::_config[$configKey]
    }

    static hidden [void] SetConfigValue([string]$configKey, [PSObject]$configValue) {
        if ($false -eq ($configKey -in [VRisingServer]::_config.Keys)) {
            throw [VRisingServerException]::New("Config key '$configKey' unrecognized -- valid keys: $([VRisingServer]::_config.Keys)")
        }
        [VRisingServer]::_config[$configKey] = $configValue
        [VRisingServer]::SaveConfigFile()
        [VRisingServerLog]::Info("Updated $configKey")
    }

    static hidden [string[]] GetConfigKeys() {
        return [VRisingServer]::_config.Keys
    }

    static hidden [void] LoadConfigFile() {
        if ($false -eq (Test-Path -LiteralPath ([VRisingServer]::_configFilePath) -PathType Leaf)) {
            return
        }
        $configFileContents = Get-Content -Raw -LiteralPath ([VRisingServer]::_configFilePath) | ConvertFrom-Json
        if ($true -eq ($configFileContents.PSObject.Properties.Name -contains 'SkipNewVersionCheck')) {
            [VRisingServer]::_config['SkipNewVersionCheck'] = $configFileContents.SkipNewVersionCheck
        }
        if ($true -eq ($configFileContents.PSObject.Properties.Name -contains 'DefaultServerDir')) {
            [VRisingServer]::_config['DefaultServerDir'] = $configFileContents.DefaultServerDir
        }
        if ($true -eq ($configFileContents.PSObject.Properties.Name -contains 'SteamCmdPath')) {
            [VRisingServer]::_config['SteamCmdPath'] = $configFileContents.SteamCmdPath
        }
    }

    static hidden [void] SaveConfigFile() {
        # get dir for path
        $configFileDir = [VRisingServer]::_configFilePath | Split-Path -Parent
        # check if dir exists
        if ($false -eq (Test-Path -LiteralPath $configFileDir -PathType Container)) {
            # create it
            New-Item -Path $configFileDir -ItemType Directory | Out-Null
        }
        $configFile = [PSCustomObject]@{
            SkipNewVersionCheck = [VRisingServer]::_config['SkipNewVersionCheck']
            DefaultServerDir = [VRisingServer]::_config['DefaultServerDir']
            SteamCmdPath = [VRisingServer]::_config['SteamCmdPath']
        }
        $configFileJson = ConvertTo-Json -InputObject $configFile -Depth 5
        $configFileJson | Out-File -LiteralPath ([VRisingServer]::_configFilePath)
        [VRisingServerLog]::Verbose("Saved main config file")
    }

    static hidden [VRisingServer[]] FindServers([string[]]$searchKeys) {
        $servers = [VRisingServer]::LoadServers()
        $foundServers = [System.Collections.ArrayList]::New()
        if (($null -eq $searchKeys) -or ($searchKeys.Count -eq 0)) {
            $searchKeys = @('*')
        }
        foreach ($searchKey in $searchKeys) {
            $serversForKey = [VRisingServer]::FindServers($searchKey, $servers)
            if ($null -ne $serversForKey) {
                $foundServers.AddRange($serversForKey)
            }
        }
        return $foundServers.ToArray([VRisingServer])
    }

    static hidden [VRisingServer] GetServer([string]$shortName) {
        return [VRisingServer]::LoadServers() | Where-Object { $_._properties.ReadProperty('ShortName') -eq $shortName }
    }

    static hidden [VRisingServer[]] FindServers([string]$searchKey, [VRisingServer[]]$servers) {
        if ([string]::IsNullOrWhiteSpace($searchKey)) {
            $searchKey = '*'
        }
        return $servers | Where-Object { $_._properties.ReadProperty('ShortName') -like $searchKey }
    }

    static hidden [VRisingServer[]] FindServers([string]$searchKey) {
        return [VRisingServer]::FindServers($searchKey, [VRisingServer]::LoadServers())
    }

    static hidden [string[]] GetShortNames() {
        return [VRisingServer]::LoadServers() | ForEach-Object { $_._properties.ReadProperty('ShortName') }
    }

    static hidden [bool] ServerFileDirExists() {
        return Test-Path -LiteralPath ([VRisingServer]::_serverFileDir) -PathType Container
    }

    static hidden [string] GetServerFilePath([string]$ShortName) {
        return Join-Path -Path ([VRisingServer]::_serverFileDir) -ChildPath "$ShortName.json"
    }

    static hidden [System.IO.FileInfo[]] GetServerFiles() {
        return Get-ChildItem `
            -Path $(Join-Path -Path ([VRisingServer]::_serverFileDir) -ChildPath '*.json') `
            -File
    }

    static hidden [VRisingServer[]] LoadServers() {
        # check if servers dir exists
        if ($false -eq ([VRisingServer]::ServerFileDirExists())) {
            return $null
        }
        $servers = [System.Collections.ArrayList]::New()
        $serverFiles = [VRisingServer]::GetServerFiles()
        foreach ($serverFile in $serverFiles) {
            $server = [VRisingServer]::LoadServer($serverFile.FullName)
            if ($null -ne $server) {
                $servers.Add($server)
            }
        }
        return $servers.ToArray([VRisingServer])
    }

    static hidden [VRisingServer] LoadServer([string]$filePath) {
        $serverFileContents = Get-Content -Raw -LiteralPath $filePath | ConvertFrom-Json
        if (($false -eq ($serverFileContents.PSObject.Properties.Name -contains 'ShortName')) -or
                ([string]::IsNullOrWhiteSpace($serverFileContents.ShortName))) {
            throw [VRisingServerException]::New("Failed loading server file at $filePath -- ShortName is missing or empty")
        }
        $server = [VRisingServer]::New($filePath, $serverFileContents.ShortName)
        [VRisingServerLog]::Verbose("[$($serverFileContents.ShortName)] server loaded from $filePath")
        return $server
    }

    static hidden [void] CreateServer([string]$ShortName) {
        if ($false -eq ($ShortName -match '^[0-9A-Za-z-_]+$')) {
            throw [VRisingServerException]::New("Server '$ShortName' is not a valid name -- allowed characters: [A-Z] [a-z] [0-9] [-] [_]")
        }
        if ([VRisingServer]::GetShortNames() -contains $ShortName) {
            throw [VRisingServerException]::New("Server '$ShortName' already exists")
        }
        $server = [VRisingServer]::New([VRisingServer]::GetServerFilePath($ShortName), $ShortName)
        $serverProperties = @{
            ShortName = $ShortName

            UpdateOnStartup = $true

            DataDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath $ShortName |
                Join-Path -ChildPath ([VRisingServer]::DATA_DIR_NAME)
            InstallDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath $ShortName |
                Join-Path -ChildPath ([VRisingServer]::INSTALL_DIR_NAME)
            LogDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath $ShortName |
                Join-Path -ChildPath ([VRisingServer]::LOG_DIR_NAME)
        }
        $server._properties.WriteProperties($serverProperties)
        [VRisingServerLog]::Info("[$($ShortName)] Server created")
    }

    static hidden [void] DeleteServer([VRisingServer]$server, [bool]$force) {
        if (($true -eq $server._processMonitor.ServerIsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server._properties.ReadProperty('ShortName'))] Cannot remove server while it is running -- Stop the server with 'vrstop' first, or use 'Force' to override")
        }
        if (($true -eq $server._processMonitor.UpdateIsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server._properties.ReadProperty('ShortName'))] Cannot remove server while it is updating -- Wait for update to complete, or use 'Force' to override")
        }
        if (($true -eq $server._processMonitor.MonitorIsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server._properties.ReadProperty('ShortName'))] Cannot remove server while the monitor is running -- Stop the monitor with 'vrdisable' first, or use 'Force' to override")
        }
        if (($true -eq $server._processMonitor.MonitorIsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server._properties.ReadProperty('ShortName'))] Cannot remove server while the monitor is enabled -- Disable the monitor with 'vrdisable' first, or use 'Force' to override")
        }
        $shortName = $($server._properties.ReadProperty('ShortName'))
        if ($true -eq (Test-Path -LiteralPath $server._properties.GetFilePath() -PathType Leaf)) {
            Remove-Item -LiteralPath $server._properties.GetFilePath()
        }
        [VRisingServerLog]::Info("[$shortName] Server removed")
    }

    # instance variables
    hidden [VRisingServerProperties] $_properties
    hidden [VRisingServerSettings] $_settings
    hidden [VRisingServerProcessMonitor] $_processMonitor

    # instance constructors
    VRisingServer([string]$filePath, [string]$shortName) {
        $this._properties = [VRisingServerProperties]::New($filePath)
        $this._settings = [VRisingServerSettings]::New($this._properties)
        $this._processMonitor = [VRisingServerProcessMonitor]::New($this._properties)
    }

    # instance methods
    [void] Start() {
        $this._processMonitor.Start()
    }

    [void] Stop([bool]$force) {
        $this._processMonitor.Stop($force)
    }

    [void] Update() {
        $this._processMonitor.Update()
    }

    [void] Restart([bool]$force) {
        $this._processMonitor.Restart($force)
    }

    [void] Enable() {
        $this._processMonitor.EnableMonitor()
    }

    [void] Disable() {
        $this._processMonitor.DisableMonitor()
    }

    hidden [string] GetCommandStatus() {
        return 'TODO: REMOVE'
        # if ($true -eq $this.CommandIsRunning()) {
        #     return 'Executing'
        # } elseif ($this._properties.ReadProperty('CommandFinished') -eq $true) {
        #     return 'OK'
        # } elseif ($this._properties.ReadProperty('CommandFinished') -eq $false) {
        #     return 'Error'
        # } else {
        #     return 'Unknown'
        # }
    }

    hidden [string] GetSavesDirPath() {
        return Join-Path -Path $this._properties.ReadProperty('DataDir') -ChildPath ([VRisingServer]::SAVES_DIR_NAME)
    }
}
