class VRisingServerProcessMonitor {
    static hidden [int] $STEAM_APP_ID = 1829350

    hidden [VRisingServerProperties] $_properties

    hidden [System.Threading.Mutex] $_processMutex
    hidden [System.Threading.Mutex] $_queueMutex

    hidden [int] $_defaultPollingRate = 1

    VRisingServerProcessMonitor([VRisingServerProperties]$properties) {
        $this._properties = $properties
    }

    [void] Run() {
        $processQueueItems = $true
        $properties = $null
        try {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] monitor is starting")
            while ($true -eq $processQueueItems) {
                $properties = $this._properties.ReadProperties(@(
                    'ShortName',
                    'ProcessMonitorEnabled'
                ))
                if ($false -eq $properties.ProcessMonitorEnabled) {
                    $processQueueItems = $false
                    [VRisingServerLog]::Info("[$($properties.ShortName)] monitor is disabled")
                    continue
                }
                $activeCommand = $this.PopCommandQueueItem()
                if ($null -ne $activeCommand) {
                    $this._properties.WriteProperty('ProcessMonitorActiveCommand', $activeCommand)
                    [VRisingServerLog]::Info("[$($properties.ShortName)] processing command: $($activeCommand.Name)")
                    switch ($activeCommand.Name) {
                        'Start' {
                            $this.LaunchServer()
                            # TODO wait for server to start and stabilize for... 30 seconds?
                            break
                        }
                        'Stop' {
                            $this.KillServer($activeCommand.Force)
                            # TODO wait for server to exit and capture exit code
                            break
                        }
                        'Update' {
                            $this.UpdateServer()
                            break
                        }
                    }
                    $this._properties.WriteProperty('ProcessMonitorActiveCommand', $null)
                    [VRisingServerLog]::Info("[$($properties.ShortName)] command processed: $($activeCommand.Name)")
                }
                if ($this.GetQueueDepth() -eq 0) {
                    # TODO ? - don't exit the monitor unless nothing is running
                    # or do we even need to monitor running processes?
                    $processQueueItems = $false
                    [VRisingServerLog]::Info("[$($properties.ShortName)] command queue empty")
                    continue
                }
                Start-Sleep -Seconds $this.GetPollingRate()
            }
        } finally {
            $this._properties.WriteProperty('ProcessMonitorActiveCommand', $null)
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] monitor is exiting")
        }
    }

    [void] Start() {
        if ($false -eq $this.IsEnabled()) {
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] cannot send Start command - server is disabled")
        }
        $this.AddCommandQueueItem(
            [pscustomobject]@{
                Name = 'Start'
            }
        )
        $this.LaunchMonitor()
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] sent Start command")
    }

    [void] Stop([bool]$force) {
        if ($false -eq $this.IsEnabled()) {
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] cannot send Stop command - server is disabled")
        }
        $this.AddCommandQueueItem(
            [pscustomobject]@{
                Name = 'Stop'
                Force = $force
            }
        )
        $this.LaunchMonitor()
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] sent Stop command")
    }

    [void] Update() {
        if ($false -eq $this.IsEnabled()) {
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] cannot send Update command - server is disabled")
        }
        $this.AddCommandQueueItem(
            [pscustomobject]@{
                Name = 'Update'
            }
        )
        $this.LaunchMonitor()
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] sent Update command")
    }

    [bool] IsEnabled() {
        return $this._properties.ReadProperty('ProcessMonitorEnabled') -eq $true
    }

    [void] Enable() {
        $this.GetProcessMutex().WaitOne()
        try {
            $this._properties.WriteProperty('ProcessMonitorEnabled', $true)
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server enabled")
        } finally {
            $this.GetProcessMutex().ReleaseMutex()
        }
        $this.LaunchMonitor()
    }

    [void] Disable() {
        $this.GetProcessMutex().WaitOne()
        try {
            $this._properties.WriteProperty('ProcessMonitorEnabled', $false)
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server disabled")
        } finally {
            $this.GetProcessMutex().ReleaseMutex()
        }
    }

    [void] KillMonitor([bool]$force) {
        if ($false -eq $this.MonitorIsRunning()) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] monitor already stopped")
            return
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] forcefully killing monitor process")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] gracefully killing monitor process")
        }
        & taskkill.exe '/PID' $this._properties.ReadProperty('ProcessMonitorProcessId') $(if ($true -eq $force) { '/F' })
    }

    [void] KillServer([bool]$force) {
        if ($false -eq $this.ServerIsRunning()) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server already stopped")
            return
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] forcefully killing server process")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] gracefully killing server process")
        }
        & taskkill.exe '/PID' $this._properties.ReadProperty('ServerProcessId') $(if ($true -eq $force) { '/F' })
    }

    [string] GetNextCommandName() {
        if ($false -eq [string]::IsNullOrEmpty($this.GetActiveCommand().Name)) {
            return $this.GetActiveCommand().Name
        } elseif ($this.GetQueueDepth() -gt 0) {
            return $this._properties.ReadProperty('ProcessMonitorCommandQueue')[0].Name
        } else {
            return $null
        }
    }

    [int] GetQueueDepth() {
        return $this._properties.ReadProperty('ProcessMonitorCommandQueue').Count
    }

    [bool] QueueIsBusy() {
        if (($null -ne $this.GetActiveCommand()) -or
                ($this.GetQueueDepth() -gt 0)) {
            return $true
        } else {
            return $false
        }
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
        } elseif ($false -eq $this.IsEnabled()) {
            return 'Disabled'
        } elseif ($this._properties.ReadProperty('LastExitCode') -ne 0) {
            return 'Error'
        } else {
            return 'Stopped'
        }
    }

    [string] GetMonitorStatus() {
        if ($true -eq $this.MonitorIsRunning()) {
            if ($true -eq $this.QueueIsBusy()) {
                return 'Busy'
            } else {
                return 'Idle'
            }
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

    hidden [pscustomobject] PopCommandQueueItem() {
        $this.GetCommandQueueMutex().WaitOne()
        try {
            $currentQueue = $this._properties.ReadProperty('ProcessMonitorCommandQueue')
            if ($currentQueue.Count -gt 0) {
                $queueItem = $currentQueue[0]
                $remainingQueue = $currentQueue[1..($currentQueue.Length)]
                $this._properties.WriteProperty('ProcessMonitorCommandQueue', $remainingQueue)
                return $queueItem
            } else {
                return $null
            }
        } finally {
            $this.GetCommandQueueMutex().ReleaseMutex()
        }
    }

    hidden [void] AddCommandQueueItem([pscustomobject]$queueItem) {
        $this.GetCommandQueueMutex().WaitOne()
        try {
            $currentQueue = $this._properties.ReadProperty('ProcessMonitorCommandQueue')
            if ($null -eq $currentQueue) {
                $updatedQueue = @($queueItem)
            } else {
                $updatedQueue = $currentQueue + $queueItem
            }
            $this._properties.WriteProperty('ProcessMonitorCommandQueue', $updatedQueue)
        } finally {
            $this.GetCommandQueueMutex().ReleaseMutex()
        }
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

    hidden [System.Threading.Mutex] GetCommandQueueMutex() {
        if ($null -eq $this._queueMutex) {
            $this._queueMutex = [System.Threading.Mutex]::New($false, "VRisingServerProcessMonitorCommandQueue-$($this._properties.ReadProperty('ShortName'))")
        }
        return $this._queueMutex
    }

    # start the update process
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function')]
    # must disable this warning due to https://stackoverflow.com/a/23797762
    # $handle is declared but not used to cause $process to cache it
    # ensures that $process can access $process.ExitCode
    hidden [void] UpdateServer() {
        if ($true -eq $this.UpdateIsRunning()) {
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] server update is already running")
        }
        if ($true -eq $this.ServerIsRunning()) {
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] server must be stopped before updating")
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
            [VRisingServerLog]::Info("[$($properties.ShortName)] starting update")
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
                [VRisingServerLog]::Error("[$($properties.ShortName)] update process exited with non-zero code: $($process.ExitCode)")
            } else {
                $updateSucceeded = $true
                [VRisingServerLog]::Info("[$($properties.ShortName)] update completed successfully")
            }
        } catch [InvalidOperationException] {
            [VRisingServerLog]::Error("[$($properties.ShortName)] failed starting update: $($_.Exception.Message)")
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
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] server already running")
        }
        if ($true -eq $this.UpdateIsRunning()) {
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] server is currently updating and cannot be started")
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
            throw [VRisingServerException]::New("[$($properties.ShortName)] server failed to start due to missing directory -- try running update first")
        } catch [InvalidOperationException] {
            throw [VRisingServerException]::New("[$($properties.ShortName)] server failed to start: $($_.Exception.Message)")
        }
        $this._properties.WriteProperties(@{
            ServerProcessName = $process.Name
            ServerProcessId = $process.Id
            ServerStdoutLogFile = $stdoutLogFile
            ServerStderrLogFile = $stderrLogFile
        })
        [VRisingServerLog]::Info("[$($properties.shortName)] server launched")
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
            [VRisingServerLog]::Info("[$($properties.shortName)] process monitor launched")
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
