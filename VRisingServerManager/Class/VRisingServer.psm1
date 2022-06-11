using module .\VRisingServerLog.psm1

$ErrorActionPreference = 'Stop'

class VRisingServer {
    # static variables
    static [string] $DefaultBaseDir
    static hidden [string] $_serverFileDir
    static hidden [hashtable] $_servers
    static hidden [string] $SAVES_DIR_NAME = 'Saves'
    static hidden [string] $SETTINGS_DIR_NAME = 'Settings'
    static hidden [string] $DATA_DIR_NAME = 'Data'
    static hidden [string] $INSTALL_DIR_NAME = 'Install'

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
            -MemberName Running `
            -MemberType ScriptProperty `
            -Value { return $this.IsRunning(); } `
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
            -MemberName FilePath `
            -MemberType ScriptProperty `
            -Value { return $this._filePath } `
            -Force
        [VRisingServer]::_serverFileDir = Join-Path `
                            -Path ([Environment]::GetEnvironmentVariable('ProgramData')) `
                            -ChildPath 'edgetools' `
                        | Join-Path -ChildPath 'VRisingServerManager' `
                        | Join-Path -ChildPath 'Servers'
        [VRisingServer]::DefaultBaseDir = 'D:\VRisingServers'
        [VRisingServer]::_servers = @{}
    }

    static hidden [VRisingServer[]] GetServers([string[]]$searchKeys) {
        $servers = [System.Collections.ArrayList]::New()
        foreach ($searchKey in $searchKeys) {
            $serversForKey = [VRisingServer]::GetServers($searchKey)
            if ($null -ne $serversForKey) {
                $servers.AddRange($serversForKey)
            }
        }
        return $servers.ToArray([VRisingServer])
    }

    static hidden [VRisingServer[]] GetServers([string]$searchKey) {
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
        if ($true -eq ($serverFileContents.PSObject.Properties.Name -contains 'ProcessId')) {
            if ($serverFileContents.ProcessId -gt 0) {
                $server._process = [VRisingServer]::GetProcessById($serverFileContents.ProcessId)
                if ($null -eq $server._process) {
                    # reset a saved server's PID back to 0 if the process isn't running when it's loaded
                    [VRisingServer]::SaveServer($server)
                } else {
                    # this assumes LoadServer only gets ran once per session
                    # not sure what happens if someone reloads the module, or if it matters
                    $server.RegisterStopEvent()
                }
            }
        }
        [VRisingServer]::_servers[$server._shortName] = $server
        [VRisingServerLog]::Info("Loaded server $($server._shortName)")
        if (($true -eq $server._autoStart) -and ($false -eq $server.IsRunning())) {
            $server.Start()
        }
    }

    static hidden [void] CreateServer([string]$ShortName) {
        if ($false -eq ($ShortName -match '^[0-9A-Za-z-_]+$')) {
            throw "server $ShortName is not a valid name -- allowed characters: [A-Z] [a-z] [0-9] [-] [_]"
        }
        if (([VRisingServer]::_servers.ContainsKey($ShortName)) -and ($null -ne [VRisingServer]::_servers[$ShortName])) {
            throw "server $ShortName already exists"
        }
        $server = [VRisingServer]::New([VRisingServer]::GetServerFilePath($ShortName))
        $server._shortName = $ShortName
        $server._updateOnStartup = $true
        $server._autoStart = $false
        $server._dataDir = Join-Path -Path ([VRisingServer]::DefaultBaseDir) -ChildPath ($server._shortName) |
            Join-Path -ChildPath ([VRisingServer]::DATA_DIR_NAME)
        $server._installDir = Join-Path -Path ([VRisingServer]::DefaultBaseDir) -ChildPath ($server._shortName) |
            Join-Path -ChildPath ([VRisingServer]::INSTALL_DIR_NAME)
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
        [PSCustomObject]@{
            ShortName = $server._shortName
            UpdateOnStartup = $server._updateOnStartup
            AutoStart = $server._autoStart
            DataDir = $server._dataDir
            InstallDir = $server._installDir
            ProcessId = if ($true -eq $server.IsRunning()) {
                            $server._process.Id
                        } else {
                            0
                        }
        } | ConvertTo-Json | Out-File -LiteralPath $server._filePath
        [VRisingServerLog]::Verbose("[VRisingServer] Saved server $($server._shortName)")
    }

    # instance variables
    hidden [bool] $_updateOnStartup
    hidden [bool] $_autoStart
    hidden [string] $_shortName
    hidden [string] $_filePath
    hidden [string] $_dataDir
    hidden [string] $_installDir
    hidden [System.Diagnostics.Process] $_process

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
            throw "server '$($this._shortName)' already running"
        }
        # $this._process = Start-Process `
        #     -WindowStyle Hidden `
        #     -WorkingDirectory 'C:\vrising' `
        #     -FilePath '.\VRisingServer.exe' `
        #     -ArgumentList @(
        #         '-persistentDataPath', 'C:\vrising_savedata',
        #         '-serverName', "ServerNameGoesHere",
        #         '-saveName', 'ShortName',
        #         '-logFile', "C:\vrising_logdata\testlog.log") `
        #     -PassThru
        # $jobDuration = $(Get-Random -Minimum 10 -Maximum 30)
        $jobDuration = 300
        $this._process = Start-Process `
            -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList @(
                '-Command', "& { `$startTime = Get-Date; while (((Get-Date) - `$startTime).TotalSeconds -le $jobDuration) { Write-Host 'Running... (Exiting after $jobDuration seconds)'; Start-Sleep -Seconds 5; } }"
            ) `
            -PassThru
        $this._process.EnableRaisingEvents = $true
        $this.RegisterStopEvent()
        [VRisingServer]::SaveServer($this)
        [VRisingServerLog]::Info("Started server $($this._shortName)")
    }

    [void] Stop([bool]$force) {
        if ($false -eq $this.IsRunning()) {
            throw "server '$($this._shortName)' already stopped"
        }
        & taskkill.exe '/PID' $this._process.Id $(if ($true -eq $force) { '/F' })
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
            [VRisingServer]::SaveServer($server)
            [VRisingServerLog]::Info("Server $($server._shortName) has stopped")
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

    hidden [string] GetDisplayName() {
        $serverHostSettings = $this.GetHostSettings()
        if ($null -ne $serverHostSettings) {
            if ($serverHostSettings.PSObject.Properties.Name -contains 'Name') {
                return $serverHostSettings.Name
            }
        }
        return $null
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

    hidden [PSCustomObject] ReadSettingsFile([string]$filePath) {
        if ($true -eq (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            return Get-Content $filePath | ConvertFrom-Json
        }
        return $null
    }
}

# custom formatters
Update-FormatData -AppendPath "$PSScriptRoot\VRisingServer.Format.ps1xml"
