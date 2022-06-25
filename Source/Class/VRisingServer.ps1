class VRisingServer {
    # static variables
    static hidden [hashtable] $_config
    static hidden [string] $_configFilePath
    static hidden [string] $_serverFileDir
    static hidden [string] $DATA_DIR_NAME = 'Data'
    static hidden [string] $SAVES_DIR_NAME = 'Saves'
    static hidden [string] $INSTALL_DIR_NAME = 'Install'
    static hidden [string] $LOG_DIR_NAME = 'Log'
    static hidden [int] $STEAM_APP_ID = 1829350

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
            -Value { return $this.GetStatus() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName LastCommand `
            -MemberType ScriptProperty `
            -Value { return $this._properties.ReadProperty('CommandType') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName LastCommandStatus `
            -MemberType ScriptProperty `
            -Value { return $this.GetCommandStatus() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName LastUpdate `
            -MemberType ScriptProperty `
            -Value { return $this.GetUpdateStatus() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName Uptime `
            -MemberType ScriptProperty `
            -Value { return $this.GetUptimeString() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName Enabled `
            -MemberType ScriptProperty `
            -Value { return $this._properties.ReadProperty('Enabled') } `
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
            -Value { return $this.GetLogFilePath([VRisingServerLogType]::File) } `
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
            DefaultServerDir = 'D:\VRisingServers'
            SteamCmdPath = $null
        }
        [VRisingServer]::LoadConfigFile()
        if (($null -eq [VRisingServer]::_config['SteamCmdPath']) -or ($true -eq ([string]::IsNullOrWhiteSpace([VRisingServer]::_config['SteamCmdPath'])))) {
            [VRisingServerLog]::Warning("SteamCmdPath is unset -- resolve using: Set-VRisingServerManagerConfigOption SteamCmdPath 'path/to/steamcmd.exe'")
        }
    }

    static hidden [string[]] GetConfigValue([string]$configKey) {
        return [VRisingServer]::_config[$configKey]
    }

    static hidden [void] SetConfigValue([string]$configKey, [PSObject]$configValue) {
        if ($false -eq ($configKey -in [VRisingServer]::_config.Keys)) {
            throw [VRisingServerException]::New("Config key '$configKey' unrecognized -- valid keys: $([VRisingServer]::_config.Keys)")
        }
        [VRisingServer]::_config[$configKey] = $configValue
        [VRisingServer]::SaveConfigFile()
    }

    static hidden [string[]] GetConfigKeys() {
        return [VRisingServer]::_config.Keys
    }

    static hidden [void] LoadConfigFile() {
        if ($false -eq (Test-Path -LiteralPath ([VRisingServer]::_configFilePath) -PathType Leaf)) {
            return
        }
        $configFileContents = Get-Content -Raw -LiteralPath ([VRisingServer]::_configFilePath) | ConvertFrom-Json
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

            Enabled = $false
            UpdateOnStartup = $true

            DataDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath $ShortName |
                Join-Path -ChildPath ([VRisingServer]::DATA_DIR_NAME)
            InstallDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath $ShortName |
                Join-Path -ChildPath ([VRisingServer]::INSTALL_DIR_NAME)
            LogDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath $ShortName |
                Join-Path -ChildPath ([VRisingServer]::LOG_DIR_NAME)

            LastExitCode = 0
            ProcessId = 0
            StdoutLogFile = $null
            StderrLogFile = $null

            UpdateLastExitCode = 0
            UpdateProcessId = 0
            UpdateStdoutLogFile = $null
            UpdateStderrLogFile = $null

            CommandType = $null
            CommandProcessId = 0
            CommandStdoutLogFile = $null
            CommandStderrLogFile = $null
            CommandFinished = $null
        }
        $server._properties.WriteProperties($serverProperties)
        [VRisingServerLog]::Info("[$($ShortName)] server created")
    }

    static hidden [void] DeleteServer([VRisingServer]$server, [bool]$force) {
        if (($true -eq $server.CommandIsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server._properties.ReadProperty('ShortName'))] cannot remove server while it is busy trying to $($server._properties.ReadProperty('CommandType')) -- wait for command to complete first or use force to override")
        }
        if (($true -eq $server.IsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server._properties.ReadProperty('ShortName'))] cannot remove server while it is running -- stop first or use force to override")
        }
        if (($true -eq $server.IsUpdating()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server._properties.ReadProperty('ShortName'))] cannot remove server while it is updating -- wait for update to complete or use force to override")
        }
        $shortName = $($server._properties.ReadProperty('ShortName'))
        if ($true -eq (Test-Path -LiteralPath $server._filePath -PathType Leaf)) {
            Remove-Item -LiteralPath $server._filePath
        }
        [VRisingServerLog]::Info("[$shortName] server removed")
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
    [bool] IsEnabled() {
        return $this._properties.ReadProperty('Enabled') -eq $true
    }

    [bool] IsRunning() {
        return $this.ProcessIsRunning($this.GetServerProcess())
    }

    [bool] IsUpdating() {
        return $this.ProcessIsRunning($this.GetUpdateProcess())
    }

    [bool] CommandIsRunning() {
        return $this.ProcessIsRunning($this.GetCommandProcess())
    }

    hidden [bool] ProcessIsRunning([System.Diagnostics.Process]$process) {
        if ($null -eq $process) {
            return $false
        } elseif ($false -eq $process.HasExited) {
            return $true
        } else {
            return $false
        }
    }

    [void] KillUpdate([bool]$force) {
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] server is busy trying to $($this._properties.ReadProperty('CommandType'))")
        }
        if ($false -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] server is not currently updating")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] forcefully stopping update process")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] gracefully stopping update process")
        }
        & taskkill.exe '/PID' $this._properties.ReadProperty('UpdateProcessId') $(if ($true -eq $force) { '/F' })
    }

    [void] KillCommand([bool]$force) {
        if ($false -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] server is not currently running a command")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] forcefully stopping $($this._properties.ReadProperty('CommandType')) process")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] gracefully stopping $($this._properties.ReadProperty('CommandType')) process")
        }
        & taskkill.exe '/PID' $this._properties.ReadProperty('CommandProcessId') $(if ($true -eq $force) { '/F' })
    }

    hidden [void] DoCommand([string]$commandType, [string]$commandString) {
        if ($false -eq $this.IsEnabled()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] server is currently disabled")
        }
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] server is busy trying to $($this._properties.ReadProperty('CommandType'))")
        }
        $properties = $this._properties.ReadProperties(@(
            'ShortName',
            'LogDir'
        ))
        $this.EnsureDirPathExists($properties.LogDir)
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.Command.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.Command.Error.log"
        $process = Start-Process `
            -FilePath 'powershell' `
            -ArgumentList "-Command & { `$ErrorActionPreference = 'Stop'; `$server = Get-VRisingServer -ShortName '$($properties.shortName)'; $commandString; }" `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutLogFile `
            -RedirectStandardError $stderrLogFile `
            -PassThru
        $this._properties.WriteProperties(@{
            CommandType = $commandType
            CommandStdoutLogFile = $stdoutLogFile
            CommandStderrLogFile = $stderrLogFile
            CommandProcessId = $process.Id
        })
        [VRisingServerLog]::Info("[$($properties.shortName)] $commandType command issued")
    }

    [void] Start() {
        $this.DoCommand('Start', "`$server.StartCommand()")
    }

    hidden [void] StartCommand() {
        $this._properties.WriteProperty('CommandFinished', $false)
        $this.DoStart()
        $this._properties.WriteProperty('CommandFinished', $true)
    }

    hidden [void] DoStart() {
        if ($true -eq $this.IsRunning()) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server already running")
            return
        }
        if ($true -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] server is currently updating and cannot be started")
        }
        $properties = $this._properties.ReadProperties(@(
            'ShortName',
            'LogDir',
            'InstallDir',
            'DataDir'
        ))
        $this.EnsureDirPathExists($properties.LogDir)
        $logFile = $this.GetLogFilePath([VRisingServerLogType]::File)
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastRun.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastRun.Error.log"
        $serverExePath = Join-Path -Path $properties.InstallDir -ChildPath 'VRisingServer.exe'
        try {
            $process = Start-Process `
                -WindowStyle Hidden `
                -RedirectStandardOutput $stdoutLogFile `
                -RedirectStandardError $stderrLogFile `
                -FilePath 'powershell' `
                -ArgumentList "Invoke-VRisingServer '$($properties.ShortName)' '$serverExePath' '$($properties.DataDir)' '$logFile'" `
                -PassThru
        } catch [System.IO.DirectoryNotFoundException] {
            throw [VRisingServerException]::New("[$($properties.ShortName)] server failed to start due to missing directory -- try running update first")
        } catch [InvalidOperationException] {
            throw [VRisingServerException]::New("[$($properties.ShortName)] server failed to start: $($_.Exception.Message)")
        }
        # $commandString = @(
        #     '$jobDuration = 120;',
        #     '$startTime = Get-Date;',
        #     'while (((Get-Date) - $startTime).TotalSeconds -le $jobDuration) {',
        #         'Write-Host \"Running... (Exiting after $($jobDuration - ([int]((Get-Date) - $startTime).TotalSeconds)) seconds)\";',
        #         'Start-Sleep -Seconds 5;',
        #     '}'
        # ) -join ' '
        # $process = Start-Process `
        #     -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        #     -ArgumentList "-Command & { $commandString }" `
        #     -WindowStyle Hidden `
        #     -RedirectStandardOutput $stdoutLogFile `
        #     -RedirectStandardError $stderrLogFile `
        #     -PassThru
        $this._properties.WriteProperties(@{
            StdoutLogFile = $stdoutLogFile
            StderrLogFile = $stderrLogFile
            ProcessId = $process.Id
            LastExitCode = 0
        })
        [VRisingServerLog]::Info("[$($properties.ShortName)] server started")
    }

    [void] Stop([bool]$force) {
        $this.DoCommand('Stop', "`$server.StopCommand([System.Convert]::ToBoolean('$force'))")
    }

    hidden [void] StopCommand([bool]$force) {
        $this._properties.WriteProperty('CommandFinished', $false)
        $this.DoStop($force)
        $this._properties.WriteProperty('CommandFinished', $true)
    }

    hidden [void] DoStop([bool]$force) {
        if ($false -eq $this.IsRunning()) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server already stopped")
            return
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] forcefully stopping server")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] gracefully stopping server")
        }
        & taskkill.exe '/PID' $this._properties.ReadProperty('ProcessId') $(if ($true -eq $force) { '/F' })
    }

    [void] Update() {
        $this.DoCommand('Update', "`$server.UpdateCommand()")
    }

    hidden [void] UpdateCommand() {
        $this._properties.WriteProperty('CommandFinished', $false)
        $this.DoUpdate()
        $this._properties.WriteProperty('CommandFinished', $true)
    }

    hidden [void] DoUpdate() {
        if ($true -eq $this.IsUpdating()) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server has already started updating")
            return
        }
        if ($true -eq $this.IsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] server must be stopped before updating")
        }
        $properties = $this._properties.ReadProperties(@(
            'ShortName',
            'LogDir',
            'InstallDir'
        ))
        $this.EnsureDirPathExists($properties.LogDir)
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastUpdate.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastUpdate.Error.log"
        $process = Start-Process `
            -FilePath ([VRisingServer]::_config['SteamCmdPath']) `
            -ArgumentList @(
                '+force_install_dir', $properties.InstallDir,
                '+login', 'anonymous',
                '+app_update', [VRisingServer]::STEAM_APP_ID,
                '+quit'
            ) `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutLogFile `
            -RedirectStandardError $stderrLogFile `
            -PassThru
        # $commandString = @(
        #     '$jobDuration = 30;',
        #     '$startTime = Get-Date;',
        #     'while (((Get-Date) - $startTime).TotalSeconds -le $jobDuration) {',
        #         'Write-Host \"Running... (Exiting after $($jobDuration - ([int]((Get-Date) - $startTime).TotalSeconds)) seconds)\";',
        #         'Start-Sleep -Seconds 5;',
        #     '}'
        # ) -join ' '
        # $process = Start-Process `
        #     -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        #     -ArgumentList @(
        #         '-Command', "& { $commandString }"
        #     ) `
        #     -WindowStyle Hidden `
        #     -RedirectStandardOutput $stdoutLogFile `
        #     -RedirectStandardError $stderrLogFile `
        #     -PassThru
        $this._properties.WriteProperties(@{
            UpdateStdoutLogFile = $stdoutLogFile
            UpdateStderrLogFile = $stderrLogFile
            UpdateProcessId = $process.Id
            UpdateLastExitCode = 0
        })
        [VRisingServerLog]::Info("[$($properties.ShortName)] update started")
    }

    [void] Restart([bool]$force) {
        $this.DoCommand('Restart', "`$server.RestartCommand([System.Convert]::ToBoolean('$force'))")
    }

    hidden [void] RestartCommand([bool]$force) {
        $this._properties.WriteProperty('CommandFinished', $false)
        if ($true -eq $this.IsRunning()) {
            $shortName = $this._properties.ReadProperty('ShortName')
            $stopTimeout = 30
            $process = $this.GetServerProcess()
            $this.DoStop($force)
            try {
                [VRisingServerLog]::Info("[$shortName] waiting on server to stop ($stopTimeout second timeout)...")
                $process | Wait-Process -Timeout $stopTimeout -ErrorAction Stop
            } catch [System.TimeoutException] {
                throw [VRisingServerException]::New("[$shortName] exceeded timeout waiting for server to stop", $_.Exception)
            }
            [VRisingServerLog]::Info("[$shortName] server stopped")
        }
        $this.DoStart()
        $this._properties.WriteProperty('CommandFinished', $true)
    }

    [void] Enable() {
        $this._properties.WriteProperty('Enabled', $true)
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server enabled")
    }

    [void] Disable() {
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] cannot disable server while it is busy trying to $($this._properties.ReadProperty('CommandType'))")
        }
        if ($true -eq $this.IsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] cannot disable server while it is running")
        }
        if ($true -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] cannot disable server while it is updating")
        }
        $this._properties.WriteProperty('Enabled', $false)
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server disabled")
    }

    hidden [string] GetStatus() {
        if ($true -eq $this.CommandIsRunning()) {
            switch($this._properties.ReadProperty('CommandType')) {
                'Restart' {
                    return 'Restarting'
                }
            }
        }
        if ($true -eq $this.IsRunning()) {
            return 'Running'
        } elseif ($true -eq $this.IsUpdating()) {
            return 'Updating'
        } elseif ($false -eq $this.IsEnabled()) {
            return 'Disabled'
        } elseif ($this._properties.ReadProperty('LastExitCode') -ne 0) {
            return 'Error'
        } else {
            return 'Stopped'
        }
    }

    hidden [string] GetUpdateStatus() {
        if ($true -eq $this.IsUpdating()) {
            return 'InProgress'
        } elseif ($this._properties.ReadProperty('UpdateLastExitCode') -ne 0) {
            return 'Failed'
        } else {
            return 'OK'
        }
    }

    hidden [string] GetCommandStatus() {
        if ($true -eq $this.CommandIsRunning()) {
            return 'Executing'
        } elseif ($this._properties.ReadProperty('CommandFinished') -eq $true) {
            return 'OK'
        } elseif ($this._properties.ReadProperty('CommandFinished') -eq $false) {
            return 'Error'
        } else {
            return 'Unknown'
        }
    }

    hidden [string] GetUptimeString() {
        $process = $this.GetServerProcess()
        if ($null -eq $process) {
            return $null
        } elseif ($true -eq $process.HasExited) {
            return $null
        } else {
            $uptime = (Get-Date) - $process.StartTime
            $uptimeString = $null
            if ($uptime.Days -gt 0) {
                $uptimeString += "$(($uptime.TotalDays -split '\.')[0])d"
            } elseif ($uptime.Hours -gt 0) {
                $uptimeString += "$(($uptime.TotalHours -split '\.')[0])h"
            } elseif ($uptime.Minutes -gt 0) {
                $uptimeString += "$(($uptime.TotalMinutes -split '\.')[0])m"
            } else {
                $uptimeString += "$(($uptime.TotalSeconds -split '\.')[0])s"
            }
            return $uptimeString
        }
    }

    hidden [void] EnsureDirPathExists([string]$dirPath) {
        if ($false -eq (Test-Path -LiteralPath $dirPath -PathType Container)) {
            New-Item -Path $dirPath -ItemType Directory | Out-Null
        }
    }

    hidden [string] GetLogFilePath([VRisingServerLogType]$logType) {
        switch ($logType) {
            ([VRisingServerLogType]::File) {
                return Join-Path -Path $this._properties.ReadProperty('LogDir') -ChildPath 'VRisingServer.log'
            }
            ([VRisingServerLogType]::Output) {
                return $this._properties.ReadProperty('StdoutLogFile')
            }
            ([VRisingServerLogType]::Error) {
                return $this._properties.ReadProperty('StderrLogFile')
            }
            ([VRisingServerLogType]::Update) {
                return $this._properties.ReadProperty('UpdateStdoutLogFile')
            }
            ([VRisingServerLogType]::UpdateError) {
                return $this._properties.ReadProperty('UpdateStderrLogFile')
            }
            ([VRisingServerLogType]::Command) {
                return $this._properties.ReadProperty('CommandStdoutLogFile')
            }
            ([VRisingServerLogType]::CommandError) {
                return $this._properties.ReadProperty('CommandStderrLogFile')
            }
        }
        return $null
    }

    hidden [string] GetSavesDirPath() {
        return Join-Path -Path $this._properties.ReadProperty('DataDir') -ChildPath ([VRisingServer]::SAVES_DIR_NAME)
    }

    hidden [System.Diagnostics.Process] GetServerProcess() {
        return $this.GetProcessByPropertyName('ProcessId')
    }

    hidden [System.Diagnostics.Process] GetUpdateProcess() {
        return $this.GetProcessByPropertyName('UpdateProcessId')
    }

    hidden [System.Diagnostics.Process] GetCommandProcess() {
        return $this.GetProcessByPropertyName('CommandProcessId')
    }

    hidden [System.Diagnostics.Process] GetProcessByPropertyName([string]$name) {
        $processId = $this._properties.ReadProperty($name)
        if ($processId -gt 0) {
            return $this.GetProcessById($processId)
        } else {
            return $null
        }
    }

    hidden [System.Diagnostics.Process] GetProcessById([int]$processId) {
        try {
            return Get-Process -Id $processId
        }
        catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
            if ('NoProcessFoundForGivenId' -eq ($_.FullyQualifiedErrorid -split ',')[0]) {
                return $null
            } else {
                throw $_
            }
        }
    }
}
