using module .\VRisingServerLog.psm1

$ErrorActionPreference = 'Stop'

enum VRisingServerLogType {
    File
    Stdout
    Stderr
    UpdateStdout
    UpdateStderr
}

class VRisingServer {
    # static variables
    static hidden [hashtable] $_config
    static hidden [string] $_configFilePath
    static hidden [string] $_serverFileDir
    static hidden [hashtable] $_servers
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
            -Value { return $this._shortName } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName DisplayName `
            -MemberType ScriptProperty `
            -Value { return $this.GetDisplayName() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName Status `
            -MemberType ScriptProperty `
            -Value { return $this.GetStatus() } `
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
            -MemberName AutoStart `
            -MemberType ScriptProperty `
            -Value { return $this._autoStart } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName UpdateOnStartup `
            -MemberType ScriptProperty `
            -Value { return $this._updateOnStartup } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName InstallDir `
            -MemberType ScriptProperty `
            -Value { return $this.GetInstallDirPath() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName DataDir `
            -MemberType ScriptProperty `
            -Value { return $this.GetDataDirPath() } `
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
            -Value { return $this.GetLogDirPath() } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName LogFile `
            -MemberType ScriptProperty `
            -Value { return $this.GetLogFilePath() } `
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
        [VRisingServer]::_servers = @{}
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
            [VRisingServerLog]::Error("config key '$configKey' unrecognized -- valid keys: $([VRisingServer]::_config.Keys)")
            return
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
        $configFileContents = Get-Content -Path ([VRisingServer]::_configFilePath) | ConvertFrom-Json
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

    static hidden [VRisingServer[]] GetServers([string[]]$searchKeys) {
        $servers = [System.Collections.ArrayList]::New()
        if (($null -eq $searchKeys) -or ($searchKeys.Count -eq 0)) {
            $searchKeys = @('*')
        }
        foreach ($searchKey in $searchKeys) {
            $serversForKey = [VRisingServer]::GetServers($searchKey)
            if ($null -ne $serversForKey) {
                $servers.AddRange($serversForKey)
            }
        }
        return $servers.ToArray([VRisingServer])
    }

    static hidden [VRisingServer[]] GetServers([string]$searchKey) {
        if ([string]::IsNullOrWhiteSpace($searchKey)) {
            $searchKey = '*'
        }
        $servers = [VRisingServer]::_servers.Values |
                        Where-Object { $_._shortName -like $searchKey }
        return $servers
    }

    static hidden [string[]] GetShortNames() {
        return [VRisingServer]::_servers.Keys
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

    static hidden [System.Diagnostics.Process] GetProcessById([int]$processId) {
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

    static hidden [void] LoadServers() {
        # check if servers dir exists
        if ($false -eq ([VRisingServer]::ServerFileDirExists())) {
            return
        }
        $serverFiles = [VRisingServer]::GetServerFiles()
        foreach ($serverFile in $serverFiles) {
            [VRisingServer]::LoadServer($serverFile.FullName)
        }
    }

    static hidden [void] LoadServer([string]$filePath) {
        $serverFileContents = Get-Content -LiteralPath $filePath | ConvertFrom-Json
        if (($false -eq ($serverFileContents.PSObject.Properties.Name -contains 'ShortName')) -or
                ([string]::IsNullOrWhiteSpace($serverFileContents.ShortName))) {
            [VRisingServerLog]::Error("failing loading server file at $filePath -- ShortName is missing or empty")
            return
        }
        if ($null -ne [VRisingServer]::_servers[$serverFileContents.ShortName]) {
            $server = [VRisingServer]::_servers[$serverFileContents.ShortName]
        } else {
            $server = [VRisingServer]::New($filePath)
        }
        $shouldSave = $false
        $server._shortName = $serverFileContents.ShortName
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'UpdateOnStartup')) {
            $server._updateOnStartup = $serverFileContents.UpdateOnStartup
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'AutoStart')) {
            $server._autoStart = $serverFileContents.AutoStart
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'DataDir')) {
            $server._dataDir = $serverFileContents.DataDir
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'InstallDir')) {
            $server._installDir = $serverFileContents.InstallDir
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'LogDir')) {
            $server._logDir = $serverFileContents.LogDir
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'LogFile')) {
            $server._logFile = $serverFileContents.LogFile
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'LastExitCode')) {
            $server._lastExitCode = $serverFileContents.LastExitCode
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'ProcessId')) {
            if ($serverFileContents.ProcessId -gt 0) {
                $server._process = [VRisingServer]::GetProcessById($serverFileContents.ProcessId)
                if ($null -eq $server._process) {
                    # save to ensure the old process id gets reset
                    $shouldSave = $true
                } else {
                    $server._lastExitCode = 0
                    $server.RegisterStopEvent()
                }
            }
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'StdoutLogFile')) {
            $server._stdoutLogFile = $serverFileContents.StdoutLogFile
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'StderrLogFile')) {
            $server._stderrLogFile = $serverFileContents.StderrLogFile
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'UpdateLastExitCode')) {
            $server._updateLastExitCode = $serverFileContents.UpdateLastExitCode
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'UpdateProcessId')) {
            if ($serverFileContents.UpdateProcessId -gt 0) {
                $server._updateProcess = [VRisingServer]::GetProcessById($serverFileContents.UpdateProcessId)
                if ($null -eq $server._updateProcess) {
                    # save to ensure the old process id gets reset
                    $shouldSave = $true
                } else {
                    $server._updateLastExitCode = 0
                    $server.RegisterUpdateStopEvent()
                }
            }
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'UpdateStdoutLogFile')) {
            $server._updateStdoutLogFile = $serverFileContents.UpdateStdoutLogFile
        }
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'UpdateStderrLogFile')) {
            $server._updateStderrLogFile = $serverFileContents.UpdateStderrLogFile
        }
        if ($true -eq $shouldSave) {
            [VRisingServer]::SaveServer($server)
        }
        [VRisingServer]::_servers[$server._shortName] = $server
        [VRisingServerLog]::Info("Loaded server $($server._shortName)")
        if (($true -eq $server._autoStart) -and ($false -eq $server.IsRunning())) {
            $server.Start()
        }
    }

    static hidden [void] CreateServer([string]$ShortName) {
        if ($false -eq ($ShortName -match '^[0-9A-Za-z-_]+$')) {
            [VRisingServerLog]::Error("server $ShortName is not a valid name -- allowed characters: [A-Z] [a-z] [0-9] [-] [_]")
            return
        }
        if (([VRisingServer]::_servers.ContainsKey($ShortName)) -and ($null -ne [VRisingServer]::_servers[$ShortName])) {
            [VRisingServerLog]::Error("server $ShortName already exists")
            return
        }
        $server = [VRisingServer]::New([VRisingServer]::GetServerFilePath($ShortName))
        $server._shortName = $ShortName
        $server._updateOnStartup = $true
        $server._autoStart = $false
        $server._dataDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath ($server._shortName) |
            Join-Path -ChildPath ([VRisingServer]::DATA_DIR_NAME)
        $server._installDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath ($server._shortName) |
            Join-Path -ChildPath ([VRisingServer]::INSTALL_DIR_NAME)
        $server._logDir = Join-Path -Path ([VRisingServer]::_config['DefaultServerDir']) -ChildPath ($server._shortName) |
            Join-Path -ChildPath ([VRisingServer]::LOG_DIR_NAME)
        [VRisingServer]::SaveServer($server)
        [VRisingServer]::_servers[$server._shortName] = $server
        [VRisingServerLog]::Info("Created server $($server._shortName)")
    }

    static hidden [void] SaveServer([VRisingServer]$server) {
        # get dir for path
        $serverFileDir = $server._filePath | Split-Path -Parent
        # check if server dir exists
        if ($false -eq (Test-Path -LiteralPath $serverFileDir -PathType Container)) {
            # create it
            New-Item -Path $serverFileDir -ItemType Directory | Out-Null
        }
        $isRunning = $server.IsRunning()
        $isUpdating = $server.IsUpdating()
        [PSCustomObject]@{
            ShortName = $server._shortName
            UpdateOnStartup = $server._updateOnStartup
            AutoStart = $server._autoStart
            DataDir = $server._dataDir
            InstallDir = $server._installDir
            LogDir = $server._logDir
            LogFile = if ($true -eq $isRunning) {
                            $server._logFile
                        } else {
                            $null
                        }
            ProcessId = if ($true -eq $isRunning) {
                            $server._process.Id
                        } else {
                            0
                        }
            LastExitCode = if ($true -eq $isRunning) {
                            0
                        } else {
                            $server._lastExitCode
                        }
            StdoutLogFile = $server._stdoutLogFile
            StderrLogFile = $server._stderrLogFile
            UpdateProcessId = if ($true -eq $isUpdating) {
                            $server._updateProcess.Id
                        } else {
                            0
                        }
            UpdateLastExitCode = if ($true -eq $isUpdating) {
                            0
                        } else {
                            $server._updateLastExitCode
                        }
            UpdateStdoutLogFile = $server._updateStdoutLogFile
            UpdateStderrLogFile = $server._updateStderrLogFile
        } | ConvertTo-Json | Out-File -LiteralPath $server._filePath
        [VRisingServerLog]::Verbose("Saved server $($server._shortName)")
    }

    static hidden [void] DeleteServers([string[]]$searchKeys, [bool]$force) {
        $serversToDelete = [VRisingServer]::GetServers($searchKeys)
        foreach ($serverToDelete in $serversToDelete) {
            [VRisingServer]::DeleteServer($serverToDelete, $force)
        }
    }

    static hidden [void] DeleteServer([VRisingServer]$server, [bool]$force) {
        if (($true -eq $server.IsRunning()) -and ($false -eq $force)) {
            [VRisingServerLog]::Error("cannot remove server $($server._shortName) while it is running -- stop first or use force to override")
            return
        }
        if ([VRisingServer]::_servers.ContainsKey($server._shortName)) {
            [VRisingServer]::_servers.Remove($server._shortName)
        }
        if ($true -eq (Test-Path -LiteralPath $server._filePath -PathType Leaf)) {
            Remove-Item -LiteralPath $server._filePath
        }
        [VRisingServerLog]::Info("Removed server $($server._shortName)")
    }

    static hidden [void] StartServers([string]$searchKeys) {
        $servers = [VRisingServer]::GetServers($searchKeys)
        foreach ($server in $servers) {
            $server.Start()
        }
    }

    static hidden [void] StopServers([string]$searchKeys, [bool]$force) {
        $servers = [VRisingServer]::GetServers($searchKeys)
        foreach ($server in $servers) {
            $server.Stop($force)
        }
    }

    static hidden [void] UpdateServers([string]$searchKeys) {
        $servers = [VRisingServer]::GetServers($searchKeys)
        foreach ($server in $servers) {
            $server.Update()
        }
    }

    static hidden [string[][]] ReadServerLogType([string[]]$searchKey, [VRisingServerLogType]$logType) {
        $servers = [VRisingServer]::GetServers($searchKey)
        $serverLogs = [System.Collections.ArrayList]::New()
        foreach ($server in $servers) {
            $log = $server.ReadLogType($logType)
            if ($null -ne $log) {
                $serverLogs.Add($log)
            }
        }
        $serverLogsArray = $serverLogs.ToArray([string[]])
        return $serverLogsArray
    }

    # instance variables
    hidden [bool] $_updateOnStartup
    hidden [bool] $_autoStart
    hidden [string] $_shortName
    hidden [string] $_filePath
    hidden [string] $_dataDir
    hidden [string] $_installDir
    hidden [string] $_logDir
    hidden [string] $_logFile

    hidden [System.Diagnostics.Process] $_process
    hidden [int] $_lastExitCode
    hidden [string] $_stdoutLogFile
    hidden [string] $_stderrLogFile

    hidden [System.Diagnostics.Process] $_updateProcess
    hidden [int] $_updateLastExitCode
    hidden [string] $_updateStdoutLogFile
    hidden [string] $_updateStderrLogFile

    # instance constructors
    VRisingServer([string]$filePath) {
        $this._filePath = $filePath
    }

    # instance methods
    [bool] IsRunning() {
        if ($null -eq $this._process) {
            return $false
        } elseif ($false -eq $this._process.HasExited) {
            return $true
        } else {
            return $false
        }
    }

    [bool] IsUpdating() {
        if ($null -eq $this._updateProcess) {
            return $false
        } elseif ($false -eq $this._updateProcess.HasExited) {
            return $true
        } else {
            return $false
        }
    }

    [PSCustomObject] GetHostSettings() {
        return $this.ReadSettingsFile($this.GetHostSettingsFilePath())
    }

    [PSCustomObject] GetGameSettings() {
        return $this.ReadSettingsFile($this.GetGameSettingsFilePath())
    }

    [PSCustomObject] GetVoipSettings() {
        return $this.ReadSettingsFile($this.GetVoipSettingsFilePath())
    }

    [void] Start() {
        if ($true -eq $this.IsRunning()) {
            [VRisingServerLog]::Error("server '$($this._shortName)' already running")
            return
        }
        if ($true -eq $this.IsUpdating()) {
            [VRisingServerLog]::Error("Server '$($this._shortName)' is currently updating and cannot be started")
            return
        }
        $this.EnsureLogDirExists()
        $this._logFile = "VRisingServer_$((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHHmmss.fffK")).log"
        $this._stdoutLogFile = Join-Path -Path $this._logDir -ChildPath "VRisingServer.LastRun.Info.log"
        $this._stderrLogFile = Join-Path -Path $this._logDir -ChildPath "VRisingServer.LastRun.Error.log"
        # $this._process = Start-Process `
        #     -WindowStyle Hidden `
        #     -RedirectStandardOutput $this._stdoutLogFile `
        #     -RedirectStandardError $this._stderrLogFile `
        #     -WorkingDirectory $this._installDir `
        #     -FilePath '.\VRisingServer.exe' `
        #     -ArgumentList @(
        #         '-persistentDataPath', $this._dataDir,
        #         '-logFile', $this._logFile) `
        #     -PassThru
        # $jobDuration = $(Get-Random -Minimum 10 -Maximum 30)
        $jobDuration = 300
        $this._process = Start-Process `
            -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList @(
                '-Command', "& { `$startTime = Get-Date; while (((Get-Date) - `$startTime).TotalSeconds -le $jobDuration) { Write-Host \`"Running... (Exiting after `$($jobDuration - ([int]((Get-Date) - `$startTime).TotalSeconds)) seconds)\`"; Start-Sleep -Seconds 5; } }"
            ) `
            -WindowStyle Hidden `
            -RedirectStandardOutput $this._stdoutLogFile `
            -RedirectStandardError $this._stderrLogFile `
            -PassThru
        $this._process.EnableRaisingEvents = $true
        $this.RegisterStopEvent()
        [VRisingServer]::SaveServer($this)
        [VRisingServerLog]::Info("Started server $($this._shortName)")
    }

    [void] Update() {
        if ($true -eq $this.IsRunning()) {
            [VRisingServerLog]::Error("Server '$($this._shortName)' must be stopped before updating")
            return
        }
        if ($true -eq $this.IsUpdating()) {
            [VRisingServerLog]::Error("Server '$($this._shortName)' has already started updating")
            return
        }
        $this.EnsureLogDirExists()
        $this._updateStdoutLogFile = Join-Path -Path $this._logDir -ChildPath "VRisingServer.LastUpdate.Info.log"
        $this._updateStderrLogFile = Join-Path -Path $this._logDir -ChildPath "VRisingServer.LastUpdate.Error.log"
        # $this._updateProcess = Start-Process `
        #     -FilePath ([VRisingServer]::_config['SteamCmdPath']) `
        #     -ArgumentList @(
        #         '+force_install_dir', $this._installDir,
        #         '+login', 'anonymous',
        #         '+app_update', [VRisingServer]::STEAM_APP_ID,
        #         '+quit'
        #     ) `
        #     -WindowStyle Hidden `
        #     -RedirectStandardOutput $this._updateStdoutLogFile `
        #     -RedirectStandardError $this._updateStderrLogFile `
        #     -PassThru
        $jobDuration = 30
        $this._updateProcess = Start-Process `
            -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList @(
                '-Command', "& { `$startTime = Get-Date; while (((Get-Date) - `$startTime).TotalSeconds -le $jobDuration) { Write-Host \`"Running... (Exiting after `$($jobDuration - ([int]((Get-Date) - `$startTime).TotalSeconds)) seconds)\`"; Start-Sleep -Seconds 5; } }"
            ) `
            -WindowStyle Hidden `
            -RedirectStandardOutput $this._updateStdoutLogFile `
            -RedirectStandardError $this._updateStderrLogFile `
            -PassThru
        $this._updateProcess.EnableRaisingEvents = $true
        $this.RegisterUpdateStopEvent()
        [VRisingServer]::SaveServer($this)
        [VRisingServerLog]::Info("Updating server $($this._shortName)")
    }

    [void] Stop([bool]$force) {
        if ($false -eq $this.IsRunning()) {
            [VRisingServerLog]::Error("Server '$($this._shortName)' already stopped")
            return
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("Forcefully stopping server $($this._shortName)")
        } else {
            [VRisingServerLog]::Info("Gracefully stopping server $($this._shortName)")
        }
        & taskkill.exe '/PID' $this._process.Id $(if ($true -eq $force) { '/F' })
    }

    [void] StopUpdate([bool]$force) {
        if ($false -eq $this.IsUpdating()) {
            [VRisingServerLog]::Error("Server '$($this._shortName)' is not currently updating")
            return
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("Forcefully stopping update process for $($this._shortName)")
        } else {
            [VRisingServerLog]::Info("Gracefully stopping update process for $($this._shortName)")
        }
        & taskkill.exe '/PID' $this._updateProcess.Id $(if ($true -eq $force) { '/F' })
    }

    hidden [void] RegisterStopEvent() {
        # don't duplicate for existing jobs
        $subscribersForExitedEvent = Get-EventSubscriber |
            Where-Object { $_.SourceObject.Id -eq $this._process.Id -and $_.EventName -eq 'Exited' }
        if (($null -ne $subscribersForExitedEvent) -and ($subscribersForExitedEvent.Count -gt 0)) {
            return
        }
        Register-ObjectEvent `
                -InputObject $this._process `
                -EventName Exited `
                -MessageData $this._shortName `
                -Action {
            # this runs automatically when the process exits
            $server = [VRisingServer]::_servers[$Event.MessageData]
            $server._process = $null
            $server._lastExitCode = $Sender.ExitCode
            [VRisingServer]::SaveServer($server)
            if ($Sender.ExitCode -eq 0) {
                [VRisingServerLog]::Info("Server $($server._shortName) has stopped successfully")
            } else {
                [VRisingServerLog]::FakeError("Server $($server._shortName) stopped with non-zero exit code $($Sender.ExitCode)")
            }
            Unregister-Event -SubscriptionId $Event.EventIdentifier
            Remove-Job -Name $Event.SourceIdentifier
        } | Out-Null
    }

    hidden [void] RegisterUpdateStopEvent() {
        # don't duplicate for existing jobs
        $subscribersForExitedEvent = Get-EventSubscriber |
            Where-Object { $_.SourceObject.Id -eq $this._updateProcess.Id -and $_.EventName -eq 'Exited' }
        if (($null -ne $subscribersForExitedEvent) -and ($subscribersForExitedEvent.Count -gt 0)) {
            return
        }
        Register-ObjectEvent `
                -InputObject $this._updateProcess `
                -EventName Exited `
                -MessageData $this._shortName `
                -Action {
            # this runs automatically when the process exits
            $server = [VRisingServer]::_servers[$Event.MessageData]
            $server._updateProcess = $null
            $server._updateLastExitCode = $Sender.ExitCode
            [VRisingServer]::SaveServer($server)
            if ($Sender.ExitCode -eq 0) {
                [VRisingServerLog]::Info("Update process for $($server._shortName) has exited successfully")
            } else {
                [VRisingServerLog]::FakeError("Update process for $($server._shortName) returned non-zero exit code $($Sender.ExitCode)")
            }
            Unregister-Event -SubscriptionId $Event.EventIdentifier
            Remove-Job -Name $Event.SourceIdentifier
        } | Out-Null
    }

    hidden [string] GetSettingsDirPath() {
        return Join-Path -Path $this._dataDir -ChildPath ([VRisingServer]::SETTINGS_DIR_NAME)
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

    hidden [string] GetSavesDirPath() {
        return Join-Path -Path $this._dataDir -ChildPath ([VRisingServer]::SAVES_DIR_NAME)
    }

    hidden [string] GetDataDirPath() {
        return $this._dataDir
    }

    hidden [string] GetInstallDirPath() {
        return $this._installDir
    }

    hidden [string] GetLogDirPath() {
        return $this._logDir
    }

    hidden [string] GetLogFilePath() {
        return $this._logFile
    }

    hidden [string] GetDisplayName() {
        $serverHostSettings = $this.GetHostSettings()
        if ($null -ne $serverHostSettings) {
            if ($serverHostSettings.PSObject.Properties.Name -contains 'Name') {
                return $serverHostSettings.Name
            }
        }
        return $null
    }

    hidden [string] GetStatus() {
        if ($true -eq $this.IsRunning()) {
            return 'Running'
        } elseif ($true -eq $this.IsUpdating()) {
            return 'Updating'
        } elseif ($this._lastExitCode -ne 0) {
            return 'Error'
        } else {
            return 'Stopped'
        }
    }

    hidden [string] GetUpdateStatus() {
        if ($true -eq $this.IsUpdating()) {
            return 'InProgress'
        } elseif ($this._updateLastExitCode -ne 0) {
            return 'Failed'
        } else {
            return 'OK'
        }
    }

    hidden [string] GetUptimeString() {
        if ($null -eq $this._process) {
            return $null
        } elseif ($true -eq $this._process.HasExited) {
            return $null
        } else {
            $uptime = (Get-Date) - $this._process.StartTime
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

    hidden [void] EnsureLogDirExists() {
        if ($false -eq (Test-Path -LiteralPath $this._logDir -PathType Container)) {
            New-Item -Path $this._logDir -ItemType Directory | Out-Null
        }
    }

    hidden [PSCustomObject] ReadSettingsFile([string]$filePath) {
        if ($true -eq (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            return Get-Content $filePath | ConvertFrom-Json
        }
        return $null
    }

    hidden [string[]] ReadLogType([VRisingServerLogType]$logType) {
        $logFile = $null
        switch ($logType) {
            ([VRisingServerLogType]::File) {
                $logFile = $this._logFile
                break
            }
            ([VRisingServerLogType]::Stdout) {
                $logFile = $this._stdoutLogFile
                break
            }
            ([VRisingServerLogType]::Stderr) {
                $logFile = $this._stderrLogFile
                break
            }
            ([VRisingServerLogType]::UpdateStdout) {
                $logFile = $this._updateStdoutLogFile
                break
            }
            ([VRisingServerLogType]::UpdateStderr) {
                $logFile = $this._updateStderrLogFile
                break
            }
        }
        if ($false -eq [string]::IsNullOrWhiteSpace($logFile)) {
            return Get-Content -LiteralPath $logFile
        }
        return $null
    }
}

# custom formatters
Update-FormatData -AppendPath "$PSScriptRoot\VRisingServer.Format.ps1xml"
