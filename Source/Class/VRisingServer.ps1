enum VRisingServerLogType {
    File
    Output
    Error
    Update
    UpdateError
    Command
    CommandError
}

enum VRisingServerSettingsType {
    Host
    Game
    Voip
}

class VRisingServer {
    # static variables
    static hidden [hashtable] $_config
    static hidden [string] $_configFilePath
    static hidden [string] $_serverFileDir
    static hidden [string] $SAVES_DIR_NAME = 'Saves'
    static hidden [string] $SETTINGS_DIR_NAME = 'Settings'
    static hidden [string] $DATA_DIR_NAME = 'Data'
    static hidden [string] $INSTALL_DIR_NAME = 'Install'
    static hidden [string] $LOG_DIR_NAME = 'Log'
    static hidden [int] $STEAM_APP_ID = 1829350

    # static constructor
    static VRisingServer() {
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName ShortName `
            -MemberType ScriptProperty `
            -Value { return $this.ReadProperty('ShortName') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName SaveName `
            -MemberType ScriptProperty `
            -Value { return $this.GetHostSetting('SaveName') } `
            -SecondValue { param($value) $this.SetHostSetting('SaveName',  $value) } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName DisplayName `
            -MemberType ScriptProperty `
            -Value { return $this.GetHostSetting('Name') } `
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
            -Value { return $this.ReadProperty('CommandType') } `
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
            -Value { return $this.ReadProperty('Enabled') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName UpdateOnStartup `
            -MemberType ScriptProperty `
            -Value { return $this.ReadProperty('UpdateOnStartup') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName InstallDir `
            -MemberType ScriptProperty `
            -Value { return $this.ReadProperty('InstallDir') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName DataDir `
            -MemberType ScriptProperty `
            -Value { return $this.ReadProperty('DataDir') } `
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
            -Value { return $this.ReadProperty('LogDir') } `
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
        [PSCustomObject]@{
            DefaultServerDir = [VRisingServer]::_config['DefaultServerDir']
            SteamCmdPath = [VRisingServer]::_config['SteamCmdPath']
        } | ConvertTo-Json | Out-File -LiteralPath ([VRisingServer]::_configFilePath)
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
        return [VRisingServer]::LoadServers() | Where-Object { $_.ReadProperty('ShortName') -eq $shortName }
    }

    static hidden [VRisingServer[]] FindServers([string]$searchKey, [VRisingServer[]]$servers) {
        if ([string]::IsNullOrWhiteSpace($searchKey)) {
            $searchKey = '*'
        }
        return $servers | Where-Object { $_.ReadProperty('ShortName') -like $searchKey }
    }

    static hidden [VRisingServer[]] FindServers([string]$searchKey) {
        return [VRisingServer]::FindServers($searchKey, [VRisingServer]::LoadServers())
    }

    static hidden [string[]] GetShortNames() {
        return [VRisingServer]::LoadServers() | ForEach-Object { $_.ReadProperty('ShortName') }
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
        $server.WriteProperties($serverProperties)
        [VRisingServerLog]::Info("[$($ShortName)] server created")
    }

    static hidden [void] DeleteServer([VRisingServer]$server, [bool]$force) {
        if (($true -eq $server.CommandIsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server.ReadProperty('ShortName'))] cannot remove server while it is busy trying to $($server.ReadProperty('CommandType')) -- wait for command to complete first or use force to override")
        }
        if (($true -eq $server.IsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server.ReadProperty('ShortName'))] cannot remove server while it is running -- stop first or use force to override")
        }
        if (($true -eq $server.IsUpdating()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New("[$($server.ReadProperty('ShortName'))] cannot remove server while it is updating -- wait for update to complete or use force to override")
        }
        $shortName = $($server.ReadProperty('ShortName'))
        if ($true -eq (Test-Path -LiteralPath $server._filePath -PathType Leaf)) {
            Remove-Item -LiteralPath $server._filePath
        }
        [VRisingServerLog]::Info("[$shortName] server removed")
    }

    static hidden [psobject[]] GetSuggestedSettingsValues(
            [VRisingServerSettingsType]$settingsType,
            [string]$shortName,
            [string]$settingName,
            [string]$settingValueSearchKey) {
        # take type
        # lookup name in type map
        # if value type (from map) is a collection type (has multiple known values):
        # - return collection matching input, sorted preferring input
        # - e.g. Host ListOnMasterServer '' -> True / False
        #        Host ListOnMasterServer 'Fa' -> False / True
        # if value type is not a collection type (has multiple known values):
        # - reach into settings
        # - extract the current or default value
        # - e.g. Host AutoSaveCount '' -> 50
        $mapResults = [VRisingServerSettingsMap]::Get($settingsType, $settingName)
        if (($null -ne $mapResults) -and ($mapResults.Count -gt 0)) {
            # sort array results by those like result
            $sortedMapResults = [System.Collections.ArrayList]::New()
            foreach ($mapResult in $mapResults) {
                if ($mapResult -like "$settingValueSearchKey*") {
                    $sortedMapResults.Insert(0, $mapResult)
                } else {
                    $sortedMapResults.Add($mapResult)
                }
            }
            return $sortedMapResults.ToArray()
        }
        # value does not have known values, try to grab current value from server instead
        if ([string]::IsNullOrWhiteSpace($shortName)) {
            return $null
        }
        $server = [VRisingServer]::GetServer($shortName)
        return $server.GetSettingsTypeValue($settingsType, $settingName)
    }

    # instance variables
    hidden [string] $_filePath

    hidden [System.Threading.Mutex] $_propertiesFileMutex
    hidden [System.Threading.Mutex] $_settingsFileMutex

    # instance constructors
    VRisingServer([string]$filePath, [string]$shortName) {
        $this._filePath = $filePath
        $this._propertiesFileMutex = [System.Threading.Mutex]::New($false, "VRisingServer-$shortName-properties")
        $this._settingsFileMutex = [System.Threading.Mutex]::New($false, "VRisingServer-$shortName-settings")
    }

    # instance methods
    [bool] IsEnabled() {
        return $this.ReadProperty('Enabled') -eq $true
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
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] server is busy trying to $($this.ReadProperty('CommandType'))")
        }
        if ($false -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] server is not currently updating")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] forcefully stopping update process")
        } else {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] gracefully stopping update process")
        }
        & taskkill.exe '/PID' $this.ReadProperty('UpdateProcessId') $(if ($true -eq $force) { '/F' })
    }

    [void] KillCommand([bool]$force) {
        if ($false -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] server is not currently running a command")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] forcefully stopping $($this.ReadProperty('CommandType')) process")
        } else {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] gracefully stopping $($this.ReadProperty('CommandType')) process")
        }
        & taskkill.exe '/PID' $this.ReadProperty('CommandProcessId') $(if ($true -eq $force) { '/F' })
    }

    hidden [void] DoCommand([string]$commandType, [string]$commandString) {
        if ($false -eq $this.IsEnabled()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] server is currently disabled")
        }
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] server is busy trying to $($this.ReadProperty('CommandType'))")
        }
        $properties = $this.ReadProperties(@(
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
        $this.WriteProperties(@{
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
        $this.WriteProperty('CommandFinished', $false)
        $this.DoStart()
        $this.WriteProperty('CommandFinished', $true)
    }

    hidden [void] DoStart() {
        if ($true -eq $this.IsRunning()) {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] server already running")
            return
        }
        if ($true -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] server is currently updating and cannot be started")
        }
        $properties = $this.ReadProperties(@(
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
        $this.WriteProperties(@{
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
        $this.WriteProperty('CommandFinished', $false)
        $this.DoStop($force)
        $this.WriteProperty('CommandFinished', $true)
    }

    hidden [void] DoStop([bool]$force) {
        if ($false -eq $this.IsRunning()) {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] server already stopped")
            return
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] forcefully stopping server")
        } else {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] gracefully stopping server")
        }
        & taskkill.exe '/PID' $this.ReadProperty('ProcessId') $(if ($true -eq $force) { '/F' })
    }

    [void] Update() {
        $this.DoCommand('Update', "`$server.UpdateCommand()")
    }

    hidden [void] UpdateCommand() {
        $this.WriteProperty('CommandFinished', $false)
        $this.DoUpdate()
        $this.WriteProperty('CommandFinished', $true)
    }

    hidden [void] DoUpdate() {
        if ($true -eq $this.IsUpdating()) {
            [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] server has already started updating")
            return
        }
        if ($true -eq $this.IsRunning()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] server must be stopped before updating")
        }
        $properties = $this.ReadProperties(@(
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
        $this.WriteProperties(@{
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
        $this.WriteProperty('CommandFinished', $false)
        if ($true -eq $this.IsRunning()) {
            $shortName = $this.ReadProperty('ShortName')
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
        $this.WriteProperty('CommandFinished', $true)
    }

    [void] Enable() {
        $this.WriteProperty('Enabled', $true)
        [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] server enabled")
    }

    [void] Disable() {
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] cannot disable server while it is busy trying to $($this.ReadProperty('CommandType'))")
        }
        if ($true -eq $this.IsRunning()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] cannot disable server while it is running")
        }
        if ($true -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New("[$($this.ReadProperty('ShortName'))] cannot disable server while it is updating")
        }
        $this.WriteProperty('Enabled', $false)
        [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] server disabled")
    }

    hidden [string] GetDefaultSettingsDirPath() {
        return Join-Path -Path $this.ReadProperty('InstallDir') -ChildPath 'VRisingServer_Data' |
            Join-Path -ChildPath 'StreamingAssets' |
            Join-Path -ChildPath 'Settings'
    }

    hidden [string] GetSettingsDirPath() {
        return Join-Path -Path $this.ReadProperty('DataDir') -ChildPath ([VRisingServer]::SETTINGS_DIR_NAME)
    }

    hidden [string] GetSavesDirPath() {
        return Join-Path -Path $this.ReadProperty('DataDir') -ChildPath ([VRisingServer]::SAVES_DIR_NAME)
    }

    hidden [string] GetDefaultHostSettingsFilePath() {
        return Join-Path -Path $this.GetDefaultSettingsDirPath() -ChildPath 'ServerHostSettings.json'
    }

    hidden [string] GetDefaultGameSettingsFilePath() {
        return Join-Path -Path $this.GetDefaultSettingsDirPath() -ChildPath 'ServerGameSettings.json'
    }

    hidden [string] GetHostSettingsFilePath() {
        return Join-Path -Path $this.GetSettingsDirPath() -ChildPath 'ServerHostSettings.json'
    }

    hidden [string] GetGameSettingsFilePath() {
        return Join-Path -Path $this.GetSettingsDirPath() -ChildPath 'ServerGameSettings.json'
    }

    hidden [string] GetVoipSettingsFilePath() {
        return Join-Path -Path $this.GetSettingsDirPath() -ChildPath 'ServerVoipSettings.json'
    }

    hidden [PSCustomObject] GetDefaultHostSettingsFile() {
        return $this.ReadSettingsFile($this.GetDefaultHostSettingsFilePath())
    }

    hidden [PSCustomObject] GetDefaultGameSettingsFile() {
        return $this.ReadSettingsFile($this.GetDefaultGameSettingsFilePath())
    }

    hidden [PSCustomObject] GetDefaultVoipSettingsFile() {
        return [PSCustomObject]@{
            VOIPEnabled = $false
            VOIPIssuer = $null
            VOIPSecret = $null
            VOIPAppUserId = $null
            VOIPAppUserPwd = $null
            VOIPVivoxDomain = $null
            VOIPAPIEndpoint = $null
            VOIPConversationalDistance = $null
            VOIPAudibleDistance = $null
            VOIPFadeIntensity = $null
        }
    }

    hidden [PSCustomObject] GetHostSettingsFile() {
        return $this.ReadSettingsFile($this.GetHostSettingsFilePath())
    }

    hidden [PSCustomObject] GetGameSettingsFile() {
        return $this.ReadSettingsFile($this.GetGameSettingsFilePath())
    }

    hidden [PSCustomObject] GetVoipSettingsFile() {
        return $this.ReadSettingsFile($this.GetVoipSettingsFilePath())
    }

    hidden [string] GetStatus() {
        if ($true -eq $this.CommandIsRunning()) {
            switch($this.ReadProperty('CommandType')) {
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
        } elseif ($this.ReadProperty('LastExitCode') -ne 0) {
            return 'Error'
        } else {
            return 'Stopped'
        }
    }

    hidden [string] GetUpdateStatus() {
        if ($true -eq $this.IsUpdating()) {
            return 'InProgress'
        } elseif ($this.ReadProperty('UpdateLastExitCode') -ne 0) {
            return 'Failed'
        } else {
            return 'OK'
        }
    }

    hidden [string] GetCommandStatus() {
        if ($true -eq $this.CommandIsRunning()) {
            return 'Executing'
        } elseif ($this.ReadProperty('CommandFinished') -eq $true) {
            return 'OK'
        } elseif ($this.ReadProperty('CommandFinished') -eq $false) {
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

    hidden [PSCustomObject] ReadSettingsFile([string]$filePath) {
        if ($true -eq (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            return Get-Content $filePath | ConvertFrom-Json
        }
        return $null
    }

    hidden [string] GetLogFilePath([VRisingServerLogType]$logType) {
        switch ($logType) {
            ([VRisingServerLogType]::File) {
                return Join-Path -Path $this.ReadProperty('LogDir') -ChildPath 'VRisingServer.log'
            }
            ([VRisingServerLogType]::Output) {
                return $this.ReadProperty('StdoutLogFile')
            }
            ([VRisingServerLogType]::Error) {
                return $this.ReadProperty('StderrLogFile')
            }
            ([VRisingServerLogType]::Update) {
                return $this.ReadProperty('UpdateStdoutLogFile')
            }
            ([VRisingServerLogType]::UpdateError) {
                return $this.ReadProperty('UpdateStderrLogFile')
            }
            ([VRisingServerLogType]::Command) {
                return $this.ReadProperty('CommandStdoutLogFile')
            }
            ([VRisingServerLogType]::CommandError) {
                return $this.ReadProperty('CommandStderrLogFile')
            }
        }
        return $null
    }

    hidden [psobject] ReadProperty([string]$name) {
        return $this.ReadProperties(@($name)).$name
    }

    hidden [psobject] ReadProperties([string[]]$names) {
        if ($false -eq (Test-Path -LiteralPath $this._filePath -PathType Leaf)) {
            return $null
        }
        $fileContent = Get-Content -Raw -LiteralPath $this._filePath | ConvertFrom-Json
        $properties = [hashtable]@{}
        foreach ($name in $names) {
            if ($fileContent.PSObject.Properties.Name -contains $name) {
                $properties[$name] = $fileContent.$name
            }
        }
        return [pscustomobject]$properties
    }

    hidden [void] WriteProperty([string]$name, [psobject]$value) {
        $this.WriteProperties(@{$name=$value})
    }

    hidden [void] WriteProperties([hashtable]$nameValues) {
        # get dir for path
        $serverFileDir = $this._filePath | Split-Path -Parent
        # check if server dir exists
        if ($false -eq (Test-Path -LiteralPath $serverFileDir -PathType Container)) {
            # create it
            New-Item -Path $serverFileDir -ItemType Directory | Out-Null
        }
        try {
            $this._propertiesFileMutex.WaitOne()
            # check if file exists
            if ($true -eq (Test-Path -LiteralPath $this._filePath -PathType Leaf)) {
                $fileContent = Get-Content -Raw -LiteralPath $this._filePath | ConvertFrom-Json
            } else {
                $fileContent = [PSCustomObject]@{}
            }
            foreach ($nameValue in $nameValues.GetEnumerator()) {
                if ($fileContent.PSObject.Properties.Name -contains $nameValue.Name) {
                    $fileContent.$($nameValue.Name) = $nameValue.Value
                } else {
                    $fileContent | Add-Member -MemberType NoteProperty -Name $nameValue.Name -Value $nameValue.Value
                }
            }
            $fileContent | ConvertTo-Json | Out-File -LiteralPath $this._filePath
        } finally {
            $this._propertiesFileMutex.ReleaseMutex()
        }
    }

    hidden [void] WriteSettingsFile() {
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
        $processId = $this.ReadProperty($name)
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

    hidden [string[]] FindSettingsTypeKeys([VRisingServerSettingsType]$settingsType, [string]$searchKey) {
        $settings = $null
        switch ($settingsType) {
            ([VRisingServerSettingsType]::Host) {
                $settings = $this.GetDefaultHostSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Game) {
                $settings = $this.GetDefaultGameSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Voip) {
                $settings = $this.GetDefaultVoipSettingsFile()
                break
            }
        }
        return $this.GetSettingsKeys($settings, $null) -like $searchKey
    }

    hidden [string[]] GetSettingsKeys($settings, [string]$prefix) {
        $keys = [System.Collections.ArrayList]::new()
        foreach ($property in $settings.PSObject.Properties) {
            if ($property.TypeNameOfValue -eq 'System.Management.Automation.PSCustomObject') {
                $keys.AddRange($this.GetSettingsKeys($property.Value, "$($property.Name)."))
            } else {
                $keys.Add($property.Name)
            }
        }
        for ($i = 0; $i -lt $keys.Count; $i++) {
            $keys[$i] = $prefix + $keys[$i]
        }
        return $keys.ToArray([string])
    }

    hidden [psobject] FilterSettings([psobject]$settings, [string[]]$settingNameFilter) {
        if (($null -eq $settings) -or
                ([string]::IsNullOrWhiteSpace($settingNameFilter))) {
            return $null
        }
        $filteredSettings = $null
        foreach ($settingName in $settingNameFilter) {
            $settingValue = $this.GetSetting($settings, $settingName)
            $filteredSettings = $this.SetSetting($filteredSettings, $settingName, $settingValue)
        }
        return $filteredSettings
    }

    hidden [psobject] GetSetting([psobject]$settings, [string]$settingName) {
        if ($null -eq $settings) {
            return $null
        }
        $settingNameSegments = $settingName -split '\.'
        $settingContainer = $settings
        # loop into the object
        # based on the number of segments to the path
        for ($i = 0; $i -lt $settingNameSegments.Count; $i++) {
            if ($i -eq ($settingNameSegments.Count - 1)) {
                # last item
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    return $null
                }
            } else {
                if ($null -eq $settingContainer) {
                    # parent pointed to a null value
                    return $null
                }
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    # missing sub key (given foo.bar, foo does not exist)
                    return $null
                }
                $settingContainer = $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value
            }
        }
        return $settingContainer.PSObject.Properties[$settingNameSegments[-1]].Value
    }

    hidden [void] DeleteSetting([psobject]$settings, [string]$settingName) {
        if ($null -eq $settings) {
            return
        }
        $settingNameSegments = $settingName -split '\.'
        $settingContainer = $settings
        # loop into the object
        # based on the number of segments to the path
        for ($i = 0; $i -lt $settingNameSegments.Count; $i++) {
            if ($i -eq ($settingNameSegments.Count - 1)) {
                # last item
                if ($settingContainer.PSObject.Properties.Name -contains $settingNameSegments[$i]) {
                    $settingContainer.PSObject.Properties.Remove($settingNameSegments[$i])
                }
            } else {
                if ($null -eq $settingContainer) {
                    # parent pointed to a null value
                    return
                }
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    # missing sub key (given foo.bar, foo does not exist)
                    return
                }
                $settingContainer = $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value
            }
        }
        return
    }

    # returns the modified (or new) settings object
    hidden [psobject] SetSetting([psobject]$settings, [string]$settingName, [psobject]$settingValue) {
        if ($null -eq $settings) {
            $settings = [PSCustomObject]@{}
        }
        $settingNameSegments = $settingName -split '\.'
        $settingContainer = $settings
        # loop into the object
        # based on the number of segments to the path
        for ($i = 0; $i -lt $settingNameSegments.Count; $i++) {
            if ($i -eq ($settingNameSegments.Count - 1)) {
                # last item
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    $settingContainer | Add-Member `
                        -MemberType NoteProperty `
                        -Name $settingNameSegments[$i] `
                        -Value $settingValue
                } else {
                    $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value = $settingValue
                }
            } else {
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    # missing sub key (given foo.bar, foo does not exist)
                    # add the missing key
                    $settingContainer | Add-Member `
                        -MemberType NoteProperty `
                        -Name $settingNameSegments[$i] `
                        -Value ([PSCustomObject]@{})
                }
                $settingContainer = $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value
            }
        }
        return $settings
    }

    # take a source object and merge an overlay on top of it
    # does not clone, modifies any objects passed by reference
    hidden [void] MergePSObjects([psobject]$sourceObject, [psobject]$overlay) {
        if ($null -eq $overlay) {
            return
        }
        if ($null -eq $sourceObject) {
            $sourceObject = $overlay
        }
        # iterate through the properties on the overlay
        $overlay.PSObject.Properties | ForEach-Object {
            $currentProperty = $_
            # if the sourceobject does NOT contain that property, just assign it from the overlay
            if ($sourceObject.PSObject.Properties.Name -notcontains $currentProperty.Name) {
                $sourceObject | Add-Member `
                    -MemberType NoteProperty `
                    -Name $currentProperty.Name `
                    -Value $currentProperty.Value
            }
            # if the sourceobject DOES contain that property, check first if it's a container (psobject)
            switch ($currentProperty.TypeNameOfValue) {
                'System.Management.Automation.PSCustomObject' {
                    # if it's a container, call this function on those subobjects (recursive)
                    $this.MergePSObjects($sourceObject.PSObject.Properties[$currentProperty.Name].Value, $currentProperty.Value)
                    break
                }
                Default {
                    # if it's NOT a container, just overlay the value directly on top of it
                    $sourceObject | Add-Member `
                        -MemberType NoteProperty `
                        -Name $currentProperty.Name `
                        -Value $currentProperty.Value `
                        -Force
                    break
                }
            }
        }
    }

    hidden [psobject] GetSettingsTypeValue([VRisingServerSettingsType]$settingsType, [string]$settingName) {
        $defaultSettings = $null
        $explicitSettings = $null
        switch ($settingsType) {
            ([VRisingServerSettingsType]::Host) {
                $defaultSettings = $this.GetDefaultHostSettingsFile()
                $explicitSettings = $this.GetHostSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Game) {
                $defaultSettings = $this.GetDefaultGameSettingsFile()
                $explicitSettings = $this.GetGameSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Voip) {
                $defaultSettings = $this.GetDefaultVoipSettingsFile()
                $explicitSettings = $this.GetVoipSettingsFile()
                break
            }
        }
        $this.MergePSObjects($defaultSettings, $explicitSettings)
        if ([string]::IsNullOrWhiteSpace($settingName)) {
            return $defaultSettings
        } elseif ($settingName.Contains('*')) {
            $matchedSettings = $this.GetSettingsKeys($defaultSettings, $null) -like $settingName
            $filteredSettings = $this.FilterSettings($defaultSettings, $matchedSettings)
            return $filteredSettings
        } else {
            return $this.GetSetting($defaultSettings, $settingName)
        }
    }

    [psobject] GetHostSetting([string]$settingName) {
        return $this.GetSettingsTypeValue([VRisingServerSettingsType]::Host, $settingName)
    }

    [psobject] GetGameSetting([string]$settingName) {
        return $this.GetSettingsTypeValue([VRisingServerSettingsType]::Game, $settingName)
    }

    [psobject] GetVoipSetting([string]$settingName) {
        return $this.GetSettingsTypeValue([VRisingServerSettingsType]::Voip, $settingName)
    }

    hidden [bool] ObjectsAreEqual([psobject]$a, [psobject]$b) {
        # simple dumbed down recursive comparison function
        # specifically for comparing values inside the [pscustomobject] from a loaded settings file
        # does not handle complex types
        $a_type = $a.GetType().Name
        $b_type = $b.GetType().Name
        if ($a_type -ne $b_type) {
            return $false
        }
        switch ($a_type) {
            'PSCustomObject' {
                foreach ($property in $a.PSObject.Properties.GetEnumerator()) {
                    if ($b.PSObject.Properties.Name -notcontains $property.Name) {
                        return $false
                    }
                    $a_value = $property.Value
                    $b_value = $b.PSObject.Properties[$property.Name].Value
                    $expectedComparables = @(
                        'System.Boolean',
                        'System.Int32',
                        'System.Decimal',
                        'System.String')
                    switch ($property.TypeNameOfValue) {
                        'System.Object' {
                            if ($false -eq $this.ObjectsAreEqual($a_value, $b_value)) {
                                return $false
                            }
                            continue
                        }
                        { $_ -in $expectedComparables } {
                            if ($a_value -cne $b_value) {
                                return $false
                            }
                            continue
                        }
                        Default {
                            throw [VRisingServerException]::New("ObjectsAreEqual unexpected type: $_")
                        }
                    }
                }
            }
            Default {
                return $a -eq $b
            }
        }
        return $true
    }

    hidden [void] SetSettingsTypeValue([VRisingServerSettingsType]$settingsType, [string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        if ($true -eq [string]::IsNullOrWhiteSpace($settingName)) {
            throw [VRisingServerException]::New("settingName cannot be null or empty", [System.ArgumentNullException]::New('settingName'))
        }
        try {
            $this._settingsFileMutex.WaitOne()
            # skip getting default value if it's being reset
            $defaultValue = $null
            if ($false -eq $resetToDefault) {
                $defaultSettings = $null
                switch ($settingsType) {
                    ([VRisingServerSettingsType]::Host) {
                        $defaultSettings = $this.GetDefaultHostSettingsFile()
                        break
                    }
                    ([VRisingServerSettingsType]::Game) {
                        $defaultSettings = $this.GetDefaultGameSettingsFile()
                        break
                    }
                    ([VRisingServerSettingsType]::Voip) {
                        $defaultSettings = $this.GetDefaultVoipSettingsFile()
                        break
                    }
                }
                # get default value
                $defaultValue = $this.GetSetting($defaultSettings, $settingName)
                # if default value matches suggested value, reset = true
                if ($true -eq $this.ObjectsAreEqual($defaultValue, $settingValue)) {
                    $resetToDefault = $true
                }
            }

            # read the file
            $explicitSettings = $null
            $settingsFilePath = $null
            switch ($settingsType) {
                ([VRisingServerSettingsType]::Host) {
                    $explicitSettings = $this.GetHostSettingsFile()
                    $settingsFilePath = $this.GetHostSettingsFilePath()
                    break
                }
                ([VRisingServerSettingsType]::Game) {
                    $explicitSettings = $this.GetGameSettingsFile()
                    $settingsFilePath = $this.GetGameSettingsFilePath()
                    break
                }
                ([VRisingServerSettingsType]::Voip) {
                    $explicitSettings = $this.GetVoipSettingsFile()
                    $settingsFilePath = $this.GetVoipSettingsFilePath()
                    break
                }
            }

            # reset or modify the value
            if ($true -eq $resetToDefault) {
                $this.DeleteSetting($explicitSettings, $settingName)
            } else {
                $explicitSettings = $this.SetSetting($explicitSettings, $settingName, $settingValue)
            }

            # write the file
            $explicitSettings | ConvertTo-Json | Out-File -LiteralPath $settingsFilePath
        } finally {
            # unlock mutex
            $this._settingsFileMutex.ReleaseMutex()
        }
    }

    [void] SetHostSetting([string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        $this.SetSettingsTypeValue([VRisingServerSettingsType]::Host, $settingName, $settingValue, $resetToDefault)
        [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] Host Setting '$settingName' modified")
    }

    [void] SetGameSetting([string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        $this.SetSettingsTypeValue([VRisingServerSettingsType]::Game, $settingName, $settingValue, $resetToDefault)
        [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] Game Setting '$settingName' modified")
    }

    [void] SetVoipSetting([string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        $this.SetSettingsTypeValue([VRisingServerSettingsType]::Voip, $settingName, $settingValue, $resetToDefault)
        [VRisingServerLog]::Info("[$($this.ReadProperty('ShortName'))] Voip Setting '$settingName' modified")
    }

    [void] KillMonitor() {}

    [void] StopMonitor() {}

    [void] RunMonitor() {
        $runLoop = $true
        while ($true -eq $runLoop) {
            $properties = $this._server.ReadProperties(
                'ShortName',
                'RunProcessMonitor'
            )
            if ($false -eq $properties.RunProcessMonitor) {
                $runLoop = $false
            }
            [VRisingServerLog]::Info("[$($properties.ShortName))] Monitor is Running...")
            Start-Sleep -Seconds 1
        }
    }
}
