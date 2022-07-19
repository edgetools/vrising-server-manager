class VRisingServerProcessMonitor {
    static hidden [int] $STEAM_APP_ID = 1829350
    static hidden [int] $LAUNCH_STABILIZATION_DELAY = 5

    hidden [VRisingServerProperties] $_properties
    hidden [VRisingServerSettings] $_settings

    hidden [System.Threading.Mutex] $_processMutex
    hidden [System.Threading.Mutex] $_commandMutex

    hidden [int] $_defaultPollingRate = 1

    VRisingServerProcessMonitor([VRisingServerProperties]$properties, [VRisingServerSettings]$settings) {
        $this._properties = $properties
        $this._settings = $settings
    }

    [void] Run() {
        $keepRunning = $true
        $shortName = $this._properties.ReadProperty('ShortName')
        try {
            [VRisingServerLog]::Info("[$shortName] Monitor starting")
            while ($true -eq $keepRunning) {
                $processMonitorEnabled = $this.IsEnabled()
                if ($false -eq $processMonitorEnabled) {
                    $keepRunning = $false
                    [VRisingServerLog]::Info("[$shortName] Monitor disabled")
                    continue
                }
                # check for an active command to run
                $activeCommand = $this.PopCommandQueueItem()
                if ($null -ne $activeCommand) {
                    $this.SetActiveCommand($activeCommand)
                    [VRisingServerLog]::Info("[$shortName] Processing command: $($activeCommand.Name)")
                    try {
                        $this.ProcessActiveCommand($activeCommand)
                    } catch [VRisingServerException] {
                        # don't want the monitor to crash because a command failed
                        [VRisingServerLog]::Info("[$shortName] Command error: $($_.Exception.Message)")
                    } catch {
                        # unrecognized exceptions will print more info for debugging
                        [VRisingServerLog]::Info("[$shortName] Unrecognized command error:")
                        [VRisingServerLog]::Info([VRisingServerLog]::FormatError($_))
                    }
                    $this.SetActiveCommand($null)
                    [VRisingServerLog]::Info("[$shortName] Command processed: $($activeCommand.Name)")
                }
                if ($this.GetQueueDepth() -eq 0) {
                    $keepRunning = $false
                    [VRisingServerLog]::Info("[$shortName] Command queue empty")
                    continue
                }
                Start-Sleep -Seconds $this.GetPollingRate()
            }
        } finally {
            $this.SetActiveCommand($null)
            [VRisingServerLog]::Info("[$shortName] Monitor is exiting")
        }
    }

    [void] Start([bool]$queue) {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Start'
            },
            $queue
        )
    }

    [void] Stop([bool]$queue, [bool]$force) {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Stop'
                Force = $force
            },
            $queue
        )
    }

    [void] Update([bool]$queue) {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Update'
            },
            $queue
        )
    }

    [void] Restart([bool]$queue, [bool]$force) {
        $this.SendCommand(
            [pscustomobject]@{
                Name = 'Restart'
                Force = $force
            },
            $queue
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
        [void] $this.KillProcess('Monitor', $this.GetMonitorProcess(), $force)
    }

    [void] KillServer([bool]$force) {
        $exitCode = $this.KillProcess('Server', $this.GetServerProcess(), $force)
        $this._properties.WriteProperty('ServiceProcessExitCode', $exitCode)
    }

    [void] KillUpdate([bool]$force) {
        [void] $this.KillProcess('Update', $this.GetUpdateProcess(), $force)
    }

    [psobject] GetNextCommand() {
        if ($null -ne $this.GetActiveCommand()) {
            return $this.GetActiveCommand()
        } elseif ($this.GetQueueDepth() -gt 0) {
            return $this.GetCommandQueue()[0]
        } else {
            return $null
        }
    }

    [int] GetQueueDepth() {
        return $this._properties.ReadProperty('ProcessMonitorCommandQueue').Count
    }

    [bool] IsBusy() {
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
            return $this.FormatTimespan($uptime)
        }
    }

    [string] GetTimeSinceLastUpdate() {
        $successDateString = $this._properties.ReadProperty('UpdateSuccessDate')
        if ($true -eq [string]::IsNullOrWhiteSpace($successDateString)) {
            return 'Unknown'
        }
        $successDate = [datetime]::ParseExact($successDateString, 'yyyy-MM-ddTHH:mm:ss', $null)
        $now = Get-Date
        $elapsedTime = $now - $successDate
        return $this.FormatTimespan($elapsedTime)
    }

    [string] GetStatus() {
        if ($true -eq $this.ServerIsRunning()) {
            return 'Running'
        } elseif ($true -eq $this.UpdateIsRunning()) {
            return 'Updating'
        } elseif ($null -ne $this._properties.ReadProperty('ServiceProcessExitCode')) {
            if ($this._properties.ReadProperty('ServiceProcessExitCode') -eq 0) {
                return 'Stopped'
            } else {
                return 'Error'
            }
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

    hidden [string] FormatTimespan([TimeSpan]$timeSpan) {
        $timeSpanString = $null
        if ($timeSpan.Days -gt 0) {
            $timeSpanString += "$(($timeSpan.TotalDays -split '\.')[0])d"
        } elseif ($timeSpan.Hours -gt 0) {
            $timeSpanString += "$(($timeSpan.TotalHours -split '\.')[0])h"
        } elseif ($timeSpan.Minutes -gt 0) {
            $timeSpanString += "$(($timeSpan.TotalMinutes -split '\.')[0])m"
        } else {
            $timeSpanString += "$(($timeSpan.TotalSeconds -split '\.')[0])s"
        }
        return $timeSpanString
    }

    hidden [void] ProcessActiveCommand([psobject]$activeCommand) {
        switch ($activeCommand.Name) {
            'Start' {
                $updateOnStartup = $this._settings.GetServiceSetting('UpdateOnStartup')
                if ($true -eq $updateOnStartup) {
                    $this.TryUpdate()
                }
                $this.LaunchServer()
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
                $updateOnStartup = $this._settings.GetServiceSetting('UpdateOnStartup')
                if ($true -eq $updateOnStartup) {
                    $this.TryUpdate()
                }
                $this.LaunchServer()
            }
        }
    }

    hidden [void] TryUpdate() {
        try {
            $this.UpdateServer()
        } catch [VRisingServerException] {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Update failed: $($_.Exception.Message)")
        }
    }

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function')]
    # must disable this warning due to https://stackoverflow.com/a/23797762
    # $handle is declared but not used to cause $process to cache it
    # ensures that $process can access $process.ExitCode
    hidden [int] KillProcess([string]$friendlyName, [System.Diagnostics.Process]$process, [bool]$force) {
        if ($false -eq $this.ProcessIsRunning($process)) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] $friendlyName already stopped")
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Forcefully killing $friendlyName process")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Gracefully killing $friendlyName process")
        }
        try {
            & taskkill.exe '/PID' $process.Id $(if ($true -eq $force) { '/F' })
            $handle = $process.Handle
            $process.WaitForExit()
            $exitCode = $process.ExitCode
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] $friendlyName process has stopped with exit code: $exitCode")
            return $exitCode
        } finally {
            $process.Close()
        }
    }

    hidden [void] SendCommand([psobject]$command, [bool]$queue) {
        if (($true -eq $this.IsBusy()) -and ($false -eq $queue)) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Cannot send '$($command.Name)' command -- Monitor is busy. Use -Queue to queue the command instead.")
        }
        $this.GetCommandMutex().WaitOne()
        try {
            # check again
            if (($true -eq $this.IsBusy()) -and ($false -eq $queue)) {
                throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Cannot send '$($command.Name)' command -- Monitor is busy. Use -Queue to queue the command instead.")
            }
            $this.AddCommandQueueItem($command)
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

    hidden [psobject] PopCommandQueueItem() {
        $this.GetCommandMutex().WaitOne()
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
            $this.GetCommandMutex().ReleaseMutex()
        }
    }

    hidden [void] AddCommandQueueItem([psobject]$queueItem) {
        $this.GetCommandMutex().WaitOne()
        try {
            $currentQueue = $this.GetCommandQueue()
            if ($currentQueue.Count -eq 0) {
                $updatedQueue = @($queueItem)
            } else {
                $updatedQueue = $currentQueue + $queueItem
            }
            $this.SetCommandQueue($updatedQueue)
        } finally {
            $this.GetCommandMutex().ReleaseMutex()
        }
    }

    hidden [psobject] GetCommandQueue() {
        return $this._properties.ReadProperty('ProcessMonitorCommandQueue')
    }

    hidden [void] SetCommandQueue([psobject]$queue) {
        $this._properties.WriteProperty('ProcessMonitorCommandQueue', $queue)
    }

    hidden [void] SetActiveCommand([psobject]$command) {
        $this._properties.WriteProperty('ProcessMonitorActiveCommand', $command)
    }

    hidden [psobject] GetActiveCommand() {
        return $this._properties.ReadProperty('ProcessMonitorActiveCommand')
    }

    hidden [void] EnsureValueExists([string]$value, [string]$name) {
        if ($true -eq ([string]::IsNullOrWhiteSpace($value))) {
            throw [VRisingServerException]::New("[$($this._properties.ReadProperty('ShortName'))] Value for $name is missing")
        }
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
        $shortName = $this._properties.ReadProperty('ShortName')
        if ($true -eq $this.UpdateIsRunning()) {
            throw [VRisingServerException]::New("[$shortName] Update is already running")
        }
        if ($true -eq $this.ServerIsRunning()) {
            throw [VRisingServerException]::New("[$shortName] Server must be stopped before updating")
        }
        $serviceSettings = $this._settings.GetServiceSetting('')
        $installDir = $this._settings.GetSetting($serviceSettings, 'InstallDir')
        $logDir = $this._settings.GetSetting($serviceSettings, 'LogDir')
        $this.EnsureValueExists($installDir, 'InstallDir')
        $this.EnsureValueExists($logDir, 'LogDir')
        $this.EnsureDirPathExists($logDir)
        $stdoutLogFile = Join-Path -Path $logDir -ChildPath "VRisingServer.LastUpdate.Info.log"
        $stderrLogFile = Join-Path -Path $logDir -ChildPath "VRisingServer.LastUpdate.Error.log"
        $process = $null
        $updateSucceeded = $false
        $updateDate = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        try {
            [VRisingServerLog]::Info("[$shortName] Starting update")
            $process = Start-Process `
                -FilePath ([VRisingServer]::_config['SteamCmdPath']) `
                -ArgumentList @(
                    '+force_install_dir', $installDir,
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
                throw [VRisingServerException]::New("[$shortName] Update process exited with non-zero code: $($process.ExitCode)")
            } else {
                $updateSucceeded = $true
                [VRisingServerLog]::Info("[$shortName] Update completed successfully")
            }
        } catch [InvalidOperationException] {
            throw [VRisingServerException]::New("[$shortName] Failed starting update: $($_.Exception.Message)")
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function')]
    # must disable this warning due to https://stackoverflow.com/a/23797762
    # $handle is declared but not used to cause $process to cache it
    # ensures that $process can access $process.ExitCode
    hidden [void] LaunchServer() {
        $shortName = $this._properties.ReadProperty('ShortName')
        if ($true -eq $this.ServerIsRunning()) {
            throw [VRisingServerException]::New("[$shortName] Server is already running")
        }
        if ($true -eq $this.UpdateIsRunning()) {
            throw [VRisingServerException]::New("[$shortName] Server is currently updating and cannot be started")
        }
        $serviceSettings = $this._settings.GetServiceSetting('')
        $installDir = $this._settings.GetSetting($serviceSettings, 'InstallDir')
        $dataDir = $this._settings.GetSetting($serviceSettings, 'DataDir')
        $logDir = $this._settings.GetSetting($serviceSettings, 'LogDir')
        $this.EnsureValueExists($installDir, 'InstallDir')
        $this.EnsureValueExists($dataDir, 'DataDir')
        $this.EnsureValueExists($logDir, 'LogDir')
        $this.EnsureDirPathExists($logDir)
        $gameLogFile = Join-Path -Path $logDir -ChildPath 'VRisingServer.log'
        $stdoutLogFile = Join-Path -Path $logDir -ChildPath "VRisingServer.LastRun.Info.log"
        $stderrLogFile = Join-Path -Path $logDir -ChildPath "VRisingServer.LastRun.Error.log"
        $serverExePath = Join-Path -Path $installDir -ChildPath 'VRisingServer.exe'
        $process = $null
        $exitCode = $null
        try {
            $process = Start-Process `
                -WindowStyle Hidden `
                -RedirectStandardOutput $stdoutLogFile `
                -RedirectStandardError $stderrLogFile `
                -FilePath $serverExePath `
                -ArgumentList "-persistentDataPath `"$dataDir`" -logFile `"$gameLogFile`"" `
                -PassThru
            $handle = $process.Handle
            [VRisingServerLog]::Info("[$shortName] Waiting $([VRisingServerProcessMonitor]::LAUNCH_STABILIZATION_DELAY) seconds while server launches ...")
            Start-Sleep -Seconds ([VRisingServerProcessMonitor]::LAUNCH_STABILIZATION_DELAY)
            if ($true -eq $process.HasExited) {
                $exitCode = $process.ExitCode
                throw [VRisingServerException]::New("[$shortName] Server exited early with code: $exitCode")
            } else {
                [VRisingServerLog]::Info("[$shortName] Server launched")
            }
        } catch [System.IO.DirectoryNotFoundException] {
            throw [VRisingServerException]::New("[$shortName] Server failed to start due to missing directory -- try running update first")
        } catch [InvalidOperationException] {
            throw [VRisingServerException]::New("[$shortName] Server failed to start: $($_.Exception.Message)")
        } finally {
            if ($null -ne $process) {
                $this._properties.WriteProperties(@{
                    ServiceProcessName = $process.Name
                    ServiceProcessId = $process.Id
                    ServiceProcessExitCode = $exitCode
                    ServiceGameLogFile = $gameLogFile
                    ServiceStdoutLogFile = $stdoutLogFile
                    ServiceStderrLogFile = $stderrLogFile
                })
                $process.Close
            } else {
                $this._properties.WriteProperties(@{
                    ServiceProcessName = $null
                    ServiceProcessId = $null
                    ServiceProcessExitCode = $null
                    ServiceGameLogFile = $gameLogFile
                    ServiceStdoutLogFile = $stdoutLogFile
                    ServiceStderrLogFile = $stderrLogFile
                })
            }
        }
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
            $shortName = $this._properties.ReadProperty('ShortName')
            $this._properties.WriteProperty('ProcessMonitorEnabled', $true)
            $logDir = $this._settings.GetServiceSetting('LogDir')
            $this.EnsureValueExists($logDir, 'LogDir')
            $this.EnsureDirPathExists($logDir)
            $stdoutLogFile = Join-Path -Path $logDir -ChildPath "VRisingServer.ProcessMonitor.Info.log"
            $stderrLogFile = Join-Path -Path $logDir -ChildPath "VRisingServer.ProcessMonitor.Error.log"
            $argumentList = @"
-NonInteractive -Command "& {
    `$ErrorActionPreference = 'Stop';
    if (`$null -eq `$script:VRisingServerManagerFlags) {
        `$script:VRisingServerManagerFlags = @{};
    }
    `$script:VRisingServerManagerFlags['SkipNewVersionCheck'] = `$true;
    `$script:VRisingServerManagerFlags['ShowDateTime'] = `$true;
    `$server = Get-VRisingServer -ShortName '$shortName';
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
            [VRisingServerLog]::Info("[$shortName] Monitor launched")
        } catch {
            $this.SetActiveCommand($null)
            throw $_
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
        return $this.GetProcessByProperties('ServiceProcessId', 'ServiceProcessName')
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
