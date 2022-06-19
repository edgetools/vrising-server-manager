using module .\VRisingServerLog.psm1
using module .\VRisingServerException.psm1

$ErrorActionPreference = 'Stop'

enum VRisingServerLogType {
    File
    Output
    Error
    Update
    UpdateError
    Command
    CommandError
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
            -MemberName Command `
            -MemberType ScriptProperty `
            -Value { return $this.ReadProperty('CommandType') } `
            -Force
        Update-TypeData `
            -TypeName "VRisingServer" `
            -MemberName CommandStatus `
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
            -Value { return $this.ReadProperty('LogFile') } `
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
            throw "Config key '$configKey' unrecognized -- valid keys: $([VRisingServer]::_config.Keys)"
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
        $serverFileContents = Get-Content -LiteralPath $filePath | ConvertFrom-Json
        if (($false -eq ($serverFileContents.PSObject.Properties.Name -contains 'ShortName')) -or
                ([string]::IsNullOrWhiteSpace($serverFileContents.ShortName))) {
            throw "Failed loading server file at $filePath -- ShortName is missing or empty"
        }
        $server = [VRisingServer]::New($filePath, $serverFileContents.ShortName)
        [VRisingServerLog]::Verbose("Loaded server '$($serverFileContents.ShortName)' from $filePath")
        return $server
    }

    static hidden [void] CreateServer([string]$ShortName) {
        if ($false -eq ($ShortName -match '^[0-9A-Za-z-_]+$')) {
            throw "Server '$ShortName' is not a valid name -- allowed characters: [A-Z] [a-z] [0-9] [-] [_]"
        }
        if ([VRisingServer]::GetShortNames() -contains $ShortName) {
            throw "Server '$ShortName' already exists"
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
            LogFile = $null

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
        [VRisingServerLog]::Info("Created server '$($ShortName)'")
    }

    static hidden [void] DoServers([string]$doCommandName, [psobject[]]$doCommandArgs, [string[]]$searchKeys) {
        $servers = [VRisingServer]::FindServers($searchKeys)
        [VRisingServer]::DoServers($doCommandName, $doCommandArgs, $servers)
    }

    static hidden [void] DoServers([string]$doCommandName, [psobject[]]$doCommandArgs, [string]$searchKey) {
        $servers = [VRisingServer]::FindServers($searchKey)
        [VRisingServer]::DoServers($doCommandName, $doCommandArgs, $servers)
    }

    static hidden [void] DoServers([string]$doCommandName, [psobject[]]$doCommandArgs, [VRisingServer[]]$servers) {
        $exceptions = [System.Collections.ArrayList]::New()
        foreach ($server in $servers) {
            try {
                switch($doCommandName) {
                    'Start' {
                        $server.Start()
                        break
                    }
                    'Stop' {
                        $server.Stop($doCommandArgs[0])
                        break
                    }
                    'Update' {
                        $server.Update()
                        break
                    }
                    'Delete' {
                        [VRisingServer]::DeleteServer($server, $doCommandArgs[0])
                        break
                    }
                    'Enable' {
                        $server.Enable()
                        break
                    }
                    'Disable' {
                        $server.Disable()
                        break
                    }
                }
            } catch [VRisingServerException] {
                $exceptions.Add($_.Exception)
            }
        }
        if ($exceptions.Count -gt 0) {
            throw [System.AggregateException]::New($exceptions)
        }
    }

    static hidden [void] DeleteServer([VRisingServer]$server, [bool]$force) {
        if (($true -eq $server.CommandIsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New($($server.ReadProperty('ShortName')), "Cannot remove server '$($server.ReadProperty('ShortName'))' while it is busy trying to $($server.ReadProperty('CommandType')) -- wait for command to complete first or use force to override")
        }
        if (($true -eq $server.IsRunning()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New($($server.ReadProperty('ShortName')), "Cannot remove server '$($server.ReadProperty('ShortName'))' while it is running -- stop first or use force to override")
        }
        if (($true -eq $server.IsUpdating()) -and ($false -eq $force)) {
            throw [VRisingServerException]::New($($server.ReadProperty('ShortName')), "Cannot remove server '$($server.ReadProperty('ShortName'))' while it is updating -- wait for update to complete or use force to override")
        }
        $shortName = $($server.ReadProperty('ShortName'))
        if ($true -eq (Test-Path -LiteralPath $server._filePath -PathType Leaf)) {
            Remove-Item -LiteralPath $server._filePath
        }
        [VRisingServerLog]::Info("Removed server '$shortName'")
    }

    static hidden [string[][]] ReadServerLogType([string[]]$searchKey, [VRisingServerLogType]$logType, [int]$last) {
        $servers = [VRisingServer]::FindServers($searchKey)
        $serverLogs = [System.Collections.ArrayList]::New()
        foreach ($server in $servers) {
            $log = $server.ReadLogType($logType, $last)
            if ($null -ne $log) {
                $serverLogs.Add($log)
            }
        }
        $serverLogsArray = $serverLogs.ToArray([string[]])
        return $serverLogsArray
    }

    # instance variables
    hidden [string] $_filePath

    hidden [System.Threading.Mutex] $_propertyFileMutex

    # instance constructors
    VRisingServer([string]$filePath, [string]$shortName) {
        $this._filePath = $filePath
        $this._propertyFileMutex = [System.Threading.Mutex]::New($false, "VRisingServer-$shortName")
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

    [PSCustomObject] GetHostSettings() {
        return $this.ReadSettingsFile($this.GetHostSettingsFilePath())
    }

    [PSCustomObject] GetGameSettings() {
        return $this.ReadSettingsFile($this.GetGameSettingsFilePath())
    }

    [PSCustomObject] GetVoipSettings() {
        return $this.ReadSettingsFile($this.GetVoipSettingsFilePath())
    }

    [void] KillUpdate([bool]$force) {
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' is busy trying to $($this.ReadProperty('CommandType'))")
        }
        if ($false -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' is not currently updating")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("Forcefully stopping update process for '$($this.ReadProperty('ShortName'))'")
        } else {
            [VRisingServerLog]::Info("Gracefully stopping update process for '$($this.ReadProperty('ShortName'))'")
        }
        & taskkill.exe '/PID' $this.ReadProperty('UpdateProcessId') $(if ($true -eq $force) { '/F' })
    }

    [void] KillCommand([bool]$force) {
        if ($false -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' is not currently running a command")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("Forcefully stopping $($this.ReadProperty('CommandType')) process for '$($this.ReadProperty('ShortName'))'")
        } else {
            [VRisingServerLog]::Info("Gracefully stopping $($this.ReadProperty('CommandType')) process for '$($this.ReadProperty('ShortName'))'")
        }
        & taskkill.exe '/PID' $this.ReadProperty('CommandProcessId') $(if ($true -eq $force) { '/F' })
    }

    hidden [void] DoCommand([string]$commandType, [string]$commandString) {
        if ($false -eq $this.IsEnabled()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' is currently Disabled")
        }
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' is busy trying to $($this.ReadProperty('CommandType'))")
        }
        $this.EnsureLogDirExists()
        $properties = $this.ReadProperties(@(
            'ShortName',
            'LogDir'
        ))
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.Command.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.Command.Error.log"
        $process = Start-Process `
            -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList "-Command & { `$ErrorActionPreference = 'Stop'; Import-Module VRisingServerManager; `$server = Get-VRisingServer -ShortName '$($properties.shortName)'; $commandString; }" `
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
        [VRisingServerLog]::Info("$commandType command issued for server '$($properties.shortName)'")
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
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' already running")
        }
        if ($true -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' is currently updating and cannot be started")
        }
        $this.EnsureLogDirExists()
        $properties = $this.ReadProperties(@(
            'ShortName',
            'InstallDir',
            'DataDir',
            'LogDir'
        ))
        $logFile = "VRisingServer_$((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHHmmss.fffK")).log"
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastRun.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastRun.Error.log"
        # $process = Start-Process `
        #     -WindowStyle Hidden `
        #     -RedirectStandardOutput $stdoutLogFile `
        #     -RedirectStandardError $stderrLogFile `
        #     -WorkingDirectory $properties.InstallDir `
        #     -FilePath '.\VRisingServer.exe' `
        #     -ArgumentList @(
        #         '-persistentDataPath', $properties.DataDir,
        #         '-logFile', $logFile
        #     ) `
        #     -PassThru
        $commandString = @(
            '$jobDuration = 120;',
            '$startTime = Get-Date;',
            'while (((Get-Date) - $startTime).TotalSeconds -le $jobDuration) {',
                'Write-Host \"Running... (Exiting after $($jobDuration - ([int]((Get-Date) - $startTime).TotalSeconds)) seconds)\";',
                'Start-Sleep -Seconds 5;',
            '}'
        ) -join ' '
        $process = Start-Process `
            -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList "-Command & { $commandString }" `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutLogFile `
            -RedirectStandardError $stderrLogFile `
            -PassThru
        $this.WriteProperties(@{
            LogFile = $logFile
            StdoutLogFile = $stdoutLogFile
            StderrLogFile = $stderrLogFile
            ProcessId = $process.Id
            LastExitCode = 0
        })
        [VRisingServerLog]::Info("Started server '$($properties.ShortName)'")
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
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' already stopped")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("Forcefully stopping server '$($this.ReadProperty('ShortName'))'")
        } else {
            [VRisingServerLog]::Info("Gracefully stopping server '$($this.ReadProperty('ShortName'))'")
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
        if ($true -eq $this.IsRunning()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' must be stopped before updating")
        }
        if ($true -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Server '$($this.ReadProperty('ShortName'))' has already started updating")
        }
        $this.EnsureLogDirExists()
        $properties = $this.ReadProperties(@(
            'ShortName',
            'LogDir'
        ))
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastUpdate.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastUpdate.Error.log"
        # $process = Start-Process `
        #     -FilePath ([VRisingServer]::_config['SteamCmdPath']) `
        #     -ArgumentList @(
        #         '+force_install_dir', $this.ReadProperty('InstallDir'),
        #         '+login', 'anonymous',
        #         '+app_update', [VRisingServer]::STEAM_APP_ID,
        #         '+quit'
        #     ) `
        #     -WindowStyle Hidden `
        #     -RedirectStandardOutput  $this.ReadProperty('UpdateStdoutLogFile') `
        #     -RedirectStandardError $this.ReadProperty('UpdateStderrLogFile') `
        #     -PassThru
        $commandString = @(
            '$jobDuration = 30;',
            '$startTime = Get-Date;',
            'while (((Get-Date) - $startTime).TotalSeconds -le $jobDuration) {',
                'Write-Host \"Running... (Exiting after $($jobDuration - ([int]((Get-Date) - $startTime).TotalSeconds)) seconds)\";',
                'Start-Sleep -Seconds 5;',
            '}'
        ) -join ' '
        $process = Start-Process `
            -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList @(
                '-Command', "& { $commandString }"
            ) `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutLogFile `
            -RedirectStandardError $stderrLogFile `
            -PassThru
        $this.WriteProperties(@{
            UpdateStdoutLogFile = $stdoutLogFile
            UpdateStderrLogFile = $stderrLogFile
            UpdateProcessId = $process.Id
            UpdateLastExitCode = 0
        })
        [VRisingServerLog]::Info("Updating server '$($properties.ShortName)'")
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
                [VRisingServerLog]::Info("Waiting on server '$shortName' to stop ($stopTimeout second timeout)...")
                $process | Wait-Process -Timeout $stopTimeout -ErrorAction Stop
            } catch [System.TimeoutException] {
                throw [VRisingServerException]::New($shortName, "Exceeded timeout waiting for server '$shortName' to stop")
            }
            [VRisingServerLog]::Info("Server '$shortName' has stopped")
        }
        $this.DoStart()
        $this.WriteProperty('CommandFinished', $true)
    }

    [void] Enable() {
        $this.WriteProperty('Enabled', $true)
        [VRisingServerLog]::Info("Enabled server '$($this.ReadProperty('ShortName'))'")
    }

    [void] Disable() {
        if ($true -eq $this.CommandIsRunning()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Cannot disable server '$($this.ReadProperty('ShortName'))' while it is busy trying to $($this.ReadProperty('CommandType'))")
        }
        if ($true -eq $this.IsRunning()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Cannot disable server '$($this.ReadProperty('ShortName'))' while it is running")
        }
        if ($true -eq $this.IsUpdating()) {
            throw [VRisingServerException]::New($($this.ReadProperty('ShortName')), "Cannot disable server '$($this.ReadProperty('ShortName'))' while it is updating")
        }
        $this.WriteProperty('Enabled', $false)
        [VRisingServerLog]::Info("Disabled server '$($this.ReadProperty('ShortName'))'")
    }

    hidden [string] GetSettingsDirPath() {
        return Join-Path -Path $this.ReadProperty('DataDir') -ChildPath ([VRisingServer]::SETTINGS_DIR_NAME)
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
        return Join-Path -Path $this.ReadProperty('DataDir') -ChildPath ([VRisingServer]::SAVES_DIR_NAME)
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

    hidden [void] EnsureLogDirExists() {
        $logDir = $this.ReadProperty('LogDir')
        if ($false -eq (Test-Path -LiteralPath $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory | Out-Null
        }
    }

    hidden [PSCustomObject] ReadSettingsFile([string]$filePath) {
        if ($true -eq (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            return Get-Content $filePath | ConvertFrom-Json
        }
        return $null
    }

    hidden [string[]] ReadLogType([VRisingServerLogType]$logType, [int]$last) {
        $logFile = $null
        switch ($logType) {
            ([VRisingServerLogType]::File) {
                $logFile = $this.ReadProperty('LogFile')
                break
            }
            ([VRisingServerLogType]::Output) {
                $logFile = $this.ReadProperty('StdoutLogFile')
                break
            }
            ([VRisingServerLogType]::Error) {
                $logFile = $this.ReadProperty('StderrLogFile')
                break
            }
            ([VRisingServerLogType]::Update) {
                $logFile = $this.ReadProperty('UpdateStdoutLogFile')
                break
            }
            ([VRisingServerLogType]::UpdateError) {
                $logFile = $this.ReadProperty('UpdateStderrLogFile')
                break
            }
            ([VRisingServerLogType]::Command) {
                $logFile = $this.ReadProperty('CommandStdoutLogFile')
                break
            }
            ([VRisingServerLogType]::CommandError) {
                $logFile = $this.ReadProperty('CommandStderrLogFile')
                break
            }
        }
        if ($false -eq [string]::IsNullOrWhiteSpace($logFile)) {
            $logFileContent = Get-Content -LiteralPath $logFile
            if ($last -gt 0) {
                $logFileContent = $logFileContent | Select-Object -Last $last
            }
            $logFileContent = $logFileContent | ForEach-Object { "[$($this.ReadProperty('ShortName'))] $_" }
            return $logFileContent
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
        $fileContent = Get-Content $this._filePath | ConvertFrom-Json
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
        $this._propertyFileMutex.WaitOne()
        # check if file exists
        if ($true -eq (Test-Path -LiteralPath $this._filePath -PathType Leaf)) {
            $fileContent = Get-Content $this._filePath | ConvertFrom-Json
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
        $this._propertyFileMutex.ReleaseMutex()
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
}

# custom formatters
Update-FormatData -AppendPath "$PSScriptRoot\VRisingServer.Format.ps1xml"
