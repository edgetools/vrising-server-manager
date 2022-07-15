class VRisingServerProcessMonitor {
    static hidden [int] $STEAM_APP_ID = 1829350

    hidden [VRisingServerProperties] $_properties

    hidden [System.Threading.Mutex] $_processMutex
    hidden [System.Threading.Mutex] $_commandMutex

    hidden [int] $_defaultPollingRate = 1

    VRisingServerProcessMonitor([VRisingServerProperties]$properties) {
        $this._properties = $properties
    }

    [void] Run() {
        $keepRunning = $true
        $properties = $null
        try {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Monitor starting")
            while ($true -eq $keepRunning) {
                $properties = $this._properties.ReadProperties(@(
                    'ShortName',
                    'ProcessMonitorEnabled',
                    'UpdateOnStartup'
                ))
                if ($false -eq $properties.ProcessMonitorEnabled) {
                    $keepRunning = $false
                    [VRisingServerLog]::Info("[$($properties.ShortName)] Monitor disabled")
                    continue
                }
                $activeCommand = $this.GetActiveCommand()
                if ($null -ne $activeCommand) {
                    $this._properties.WriteProperty('ProcessMonitorActiveCommand', $activeCommand)
                    [VRisingServerLog]::Info("[$($properties.ShortName)] Processing command: $($activeCommand.Name)")
                    switch ($activeCommand.Name) {
                        'Start' {
                            if ($true -eq $properties.UpdateOnStartup) {
                                $this.UpdateServer()
                            }
                            $this.LaunchServer()
                            # TODO wait for server to start and stabilize for... 30 seconds?
                            break
                        }
                        'Stop' {
                            $this.KillServer($activeCommand.Force)
                            break
                        }
                        'Update' {
                            $this.UpdateServer()
                            break
                        }
                        'Restart' {
                            if ($true -eq $this.ServerIsRunning()) {
                                $this.KillServer($activeCommand.Force)
                            }
                            if ($true -eq $properties.UpdateOnStartup) {
                                $this.UpdateServer()
                            }
                            $this.LaunchServer()
                        }
                    }
                    $this._properties.WriteProperty('ProcessMonitorActiveCommand', $null)
                    [VRisingServerLog]::Info("[$($properties.ShortName)] Command processed: $($activeCommand.Name)")
                }
                Start-Sleep -Seconds $this.GetPollingRate()
            }
        } finally {
            $this._properties.WriteProperty('ProcessMonitorActiveCommand', $null)
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Monitor is exiting")
        }
    }

    [void] Start() {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Start'
            }
        )
    }

    [void] Stop([bool]$force) {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Stop'
                Force = $force
            }
        )
    }

    [void] Update() {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Update'
            }
        )
    }

    [void] Restart([bool]$force) {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Restart'
                Force = $force
            }
        )
    }

    [bool] IsEnabled() {
        return $this._properties.ReadProperty('ProcessMonitorEnabled') -eq $true
    }

    [void] EnableMonitor() {
        $this.GetProcessMutex().WaitOne()
        try {
            $this._properties.WriteProperty('ProcessMonitorEnabled', $true)
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Monitor enabled")
        } finally {
            $this.GetProcessMutex().ReleaseMutex()
        }
        $this.LaunchMonitor()
    }

    [void] DisableMonitor() {
        $this.GetProcessMutex().WaitOne()
        try {
            $this._properties.WriteProperty('ProcessMonitorEnabled', $false)
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Monitor disabled")
        } finally {
            $this.GetProcessMutex().ReleaseMutex()
        }
    }

    [void] KillMonitor([bool]$force) {
        $this.KillProcess('Monitor', $this.GetMonitorProcess(), $force)
    }

    [void] KillServer([bool]$force) {
        $this.KillProcess('Server', $this.GetServerProcess(), $force)
    }

    [void] KillUpdate([bool]$force) {
        $this.KillProcess('Update', $this.GetUpdateProcess(), $force)
    }

    [bool] IsBusy() {
        return ($null -ne $this.GetActiveCommand())
    }

    [string] GetUptime() {
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

    [string] GetStatus() {
        if ($true -eq $this.ServerIsRunning()) {
            return 'Running'
        } elseif ($true -eq $this.UpdateIsRunning()) {
            return 'Updating'
        } elseif ($this._properties.ReadProperty('LastExitCode') -ne 0) {
            return 'Error'
        } else {
            return 'Stopped'
        }
    }

    [string] GetMonitorStatus() {
        if ($true -eq $this.MonitorIsRunning()) {
            if ($true -eq $this.IsBusy()) {
                return 'Busy'
            } else {
                return 'Idle'
            }
        } elseif ($false -eq $this.IsEnabled()) {
            return 'Disabled'
        } else {
            return 'Stopped'
        }
    }

    [string] GetUpdateStatus() {
        if ($true -eq $this.UpdateIsRunning()) {
            return 'InProgress'
        } elseif ($this._properties.ReadProperty('UpdateSuccess') -eq $false) {
            return 'Failed'
        } elseif ($this._properties.ReadProperty('UpdateSuccess') -eq $true) {
            return 'OK'
        } else {
            return 'Unknown'
        }
    }

    hidden [void] KillProcess([string]$friendlyName, [System.Diagnostics.Process]$process, [bool]$force) {
        if ($false -eq $this.ProcessIsRunning($process)) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] $friendlyName already stopped")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Forcefully killing $friendlyName process")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Gracefully killing $friendlyName process")
        }
        & taskkill.exe '/PID' $process.Id $(if ($true -eq $force) { '/F' })
        $process.WaitForExit()
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] $friendlyName process has stopped")
    }

    hidden [void] SendCommand([pscustomobject]$command) {
        if ($true -eq $this.IsBusy()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Cannot send '$($command.Name)' command -- Monitor is busy")
        }
        $this.GetCommandMutex().WaitOne()
        try {
            # check again
            if ($true -eq $this.IsBusy()) {
                throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Cannot send '$($command.Name)' command -- Monitor is busy")
            }
            $this.SetActiveCommand($command)
            $this.LaunchMonitor()
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] $($command.Name) command sent")
        }
        finally {
            $this.GetCommandMutex().ReleaseMutex()
        }
    }

    hidden [void] SetPollingRate([int]$pollingRate) {
        if ($pollingRate -gt 0) {
            $this._properties.WriteProperty('ProcessMonitorPollingRate', $pollingRate)
        }
    }

    hidden [int] GetPollingRate() {
        $pollingRate = $this._properties.ReadProperty('ProcessMonitorPollingRate')
        if ($pollingRate -gt 0) {
            return $pollingRate
        } else {
            return $this._defaultPollingRate
        }
    }

    hidden [void] SetActiveCommand([pscustomobject]$command) {
        $this._properties.WriteProperty('ProcessMonitorActiveCommand', $command)
    }

    hidden [psobject] GetActiveCommand() {
        return $this._properties.ReadProperty('ProcessMonitorActiveCommand')
    }

    hidden [void] EnsureDirPathExists([string]$dirPath) {
        if ($false -eq (Test-Path -LiteralPath $dirPath -PathType Container)) {
            New-Item -Path $dirPath -ItemType Directory | Out-Null
        }
    }

    hidden [System.Threading.Mutex] GetProcessMutex() {
        if ($null -eq $this._processMutex) {
            $this._processMutex = [System.Threading.Mutex]::New($false, "VRisingServerProcessMonitorProcess-$($this._properties.ReadProperty('ShortName'))")
        }
        return $this._processMutex
    }

    hidden [System.Threading.Mutex] GetCommandMutex() {
        if ($null -eq $this._commandMutex) {
            $this._commandMutex = [System.Threading.Mutex]::New($false, "VRisingServerProcessMonitorCommand-$($this._properties.ReadProperty('ShortName'))")
        }
        return $this._commandMutex
    }

    # start the update process
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function')]
    # must disable this warning due to https://stackoverflow.com/a/23797762
    # $handle is declared but not used to cause $process to cache it
    # ensures that $process can access $process.ExitCode
    hidden [void] UpdateServer() {
        if ($true -eq $this.UpdateIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Update is already running")
        }
        if ($true -eq $this.ServerIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Server must be stopped before updating")
        }
        $properties = $this._properties.ReadProperties(@(
            'ShortName',
            'LogDir',
            'InstallDir'
        ))
        $this.EnsureDirPathExists($properties.LogDir)
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastUpdate.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastUpdate.Error.log"
        $process = $null
        $updateSucceeded = $false
        $updateDate = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        try {
            [VRisingServerLog]::Info("[$($properties.ShortName)] Starting update")
            $process = Start-Process `
                -FilePath ([VRisingServer]::_config['SteamCmdPath']) `
                -ArgumentList @(
                    '+force_install_dir', $properties.InstallDir,
                    '+login', 'anonymous',
                    '+app_update', [VRisingServerProcessMonitor]::STEAM_APP_ID,
                    '+quit'
                ) `
                -WindowStyle Hidden `
                -RedirectStandardOutput $stdoutLogFile `
                -RedirectStandardError $stderrLogFile `
                -PassThru
            $handle = $process.Handle
            $this._properties.WriteProperties(@{
                UpdateProcessName = $process.Name
                UpdateProcessId = $process.Id
                UpdateStdoutLogFile = $stdoutLogFile
                UpdateStderrLogFile = $stderrLogFile
            })
            $process.WaitForExit()
            if ($process.ExitCode -ne 0) {
                throw [VRisingServerException]::New("[$($properties.ShortName)] Update process exited with non-zero code: $($process.ExitCode)")
            } else {
                $updateSucceeded = $true
                [VRisingServerLog]::Info("[$($properties.ShortName)] Update completed successfully")
            }
        } catch [InvalidOperationException] {
            throw [VRisingServerException]::New("[$($properties.ShortName)] Failed starting update: $($_.Exception.Message)")
        } finally {
            if ($null -ne $process) {
                $process.Close()
            }
            $properties = @{
                UpdateProcessName = $null
                UpdateProcessId = 0
                UpdateSuccess = $updateSucceeded
            }
            if ($true -eq $updateSucceeded) {
                $properties['UpdateSuccessDate'] = $updateDate
            }
            $this._properties.WriteProperties($properties)
        }
    }

    # start the server process
    hidden [void] LaunchServer() {
        if ($true -eq $this.ServerIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Server is already running")
        }
        if ($true -eq $this.UpdateIsRunning()) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Server is currently updating and cannot be Started")
        }
        $this._properties.WriteProperties(@{
            ServerProcessName = $null
            ServerProcessId = 0
        })
        $properties = $this._properties.ReadProperties(@(
            'ShortName',
            'LogDir',
            'InstallDir',
            'DataDir'
        ))
        $this.EnsureDirPathExists($properties.LogDir)
        $logFile = $this._properties.GetLogFilePath([VRisingServerLogType]::Server)
        $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastRun.Info.log"
        $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.LastRun.Error.log"
        $serverExePath = Join-Path -Path $properties.InstallDir -ChildPath 'VRisingServer.exe'
        try {
            $process = Start-Process `
                -WindowStyle Hidden `
                -RedirectStandardOutput $stdoutLogFile `
                -RedirectStandardError $stderrLogFile `
                -FilePath $serverExePath `
                -ArgumentList "-persistentDataPath `"$($properties.DataDir)`" -logFile `"$logFile`"" `
                -PassThru
        } catch [System.IO.DirectoryNotFoundException] {
            throw [VRisingServerException]::New("[$($properties.ShortName)] Server failed to start due to missing directory -- try running update first")
        } catch [InvalidOperationException] {
            throw [VRisingServerException]::New("[$($properties.ShortName)] Server failed to start: $($_.Exception.Message)")
        }
        $this._properties.WriteProperties(@{
            ServerProcessName = $process.Name
            ServerProcessId = $process.Id
            ServerStdoutLogFile = $stdoutLogFile
            ServerStderrLogFile = $stderrLogFile
        })
        [VRisingServerLog]::Info("[$($properties.shortName)] Server launched")
    }

    # start the background process
    hidden [void] LaunchMonitor() {
        # check before locking the mutex (so we don't unnecessarily block the thread)
        if ($true -eq $this.MonitorIsRunning()) {
            return
        }
        $this.GetProcessMutex().WaitOne()
        try {
            # check again just in case it was launched between checking the last statement and locking the mutex
            if ($true -eq $this.MonitorIsRunning()) {
                return
            }
            $this._properties.WriteProperties(@{
                ProcessMonitorProcessName = $null
                ProcessMonitorProcessId = 0
                ProcessMonitorEnabled = $true
            })
            $properties = $this._properties.ReadProperties(@(
                'ShortName',
                'LogDir'
            ))
            $this.EnsureDirPathExists($properties.LogDir)
            $stdoutLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.ProcessMonitor.Info.log"
            $stderrLogFile = Join-Path -Path $properties.LogDir -ChildPath "VRisingServer.ProcessMonitor.Error.log"
            $argumentList = @"
-Command "& {
    `$ErrorActionPreference = 'Stop';
    if (`$null -eq `$script:VRisingServerManagerFlags) {
        `$script:VRisingServerManagerFlags = @{};
    }
    `$script:VRisingServerManagerFlags['SkipNewVersionCheck'] = `$true;
    `$script:VRisingServerManagerFlags['ShowDateTime'] = `$true;
    `$server = Get-VRisingServer -ShortName '$($properties.shortName)';
    `$server._processMonitor.Run();
}"
"@
            $process = Start-Process `
                -FilePath 'powershell' `
                -ArgumentList $argumentList `
                -WindowStyle Hidden `
                -RedirectStandardOutput $stdoutLogFile `
                -RedirectStandardError $stderrLogFile `
                -PassThru
            $this._properties.WriteProperties(@{
                ProcessMonitorProcessName = $process.Name
                ProcessMonitorProcessId = $process.Id
                ProcessMonitorStdoutLogFile = $stdoutLogFile
                ProcessMonitorStderrLogFile = $stderrLogFile
            })
            [VRisingServerLog]::Info("[$($properties.shortName)] Monitor launched")
        } finally {
            $this.GetProcessMutex().ReleaseMutex()
        }
    }

    hidden [bool] MonitorIsRunning() {
        return $this.ProcessIsRunning($this.GetMonitorProcess())
    }

    hidden [bool] ServerIsRunning() {
        return $this.ProcessIsRunning($this.GetServerProcess())
    }

    hidden [bool] UpdateIsRunning() {
        return $this.ProcessIsRunning($this.GetUpdateProcess())
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

    hidden [System.Diagnostics.Process] GetMonitorProcess() {
        return $this.GetProcessByProperties('ProcessMonitorProcessId', 'ProcessMonitorProcessName')
    }

    hidden [System.Diagnostics.Process] GetServerProcess() {
        return $this.GetProcessByProperties('ServerProcessId', 'ServerProcessName')
    }

    hidden [System.Diagnostics.Process] GetUpdateProcess() {
        return $this.GetProcessByProperties('UpdateProcessId', 'UpdateProcessName')
    }

    hidden [System.Diagnostics.Process] GetProcessByProperties([string]$processIdKey, [string]$processNameKey) {
        $properties = $this._properties.ReadProperties(@($processIdKey, $processNameKey))
        if ($properties.$processIdKey -gt 0) {
            $process = $this.GetProcessById($properties.$processIdKey)
            if ($properties.$processNameKey -eq $process.ProcessName) {
                return $process
            } else {
                return $null
            }
        } else {
            return $null
        }
    }

    hidden [System.Diagnostics.Process] GetProcessById([int]$processId) {
        try {
            return Get-Process -Id $processId
        } catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
            if ('NoProcessFoundForGivenId' -eq ($_.FullyQualifiedErrorid -split ',')[0]) {
                return $null
            } else {
                throw $_
            }
        }
    }
}
