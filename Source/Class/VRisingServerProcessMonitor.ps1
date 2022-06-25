class VRisingServerProcessMonitor {
    hidden [VRisingServerProperties] $_properties

    hidden [System.Threading.Mutex] $_processMutex
    hidden [System.Threading.Mutex] $_queueMutex

    hidden [int] $_defaultPollingRate = 1

    VRisingServerProcessMonitor([VRisingServerProperties]$properties) {
        $this._properties = $properties
    }

    [void] Run() {
        $runLoop = $true
        $properties = $null
        try {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] monitor is starting")
            while ($true -eq $runLoop) {
                $properties = $this._properties.ReadProperties(@(
                    'ShortName',
                    'ProcessMonitorEnabled'
                ))
                if ($false -eq $properties.ProcessMonitorEnabled) {
                    $runLoop = $false
                    [VRisingServerLog]::Info("[$($properties.ShortName)] monitor is disabled")
                    continue
                }
                $activeCommand = $this.PopCommandQueueItem()
                if ($null -ne $activeCommand) {
                    $this._properties.WriteProperty('ProcessMonitorActiveCommand', $activeCommand)
                    [VRisingServerLog]::Info("[$($properties.ShortName)] processing command: $($activeCommand.CommandName)")
                    switch ($activeCommand.CommandName) {
                        'Start' {
                            [VRisingServerLog]::Info("[$($properties.ShortName)] starting server")
                            break
                        }
                        'Stop' {
                            [VRisingServerLog]::Info("[$($properties.ShortName)] stopping server")
                            break
                        }
                    }
                    $this._properties.WriteProperty('ProcessMonitorActiveCommand', $null)
                    [VRisingServerLog]::Info("[$($properties.ShortName)] command processed: $($activeCommand.CommandName)")
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
            return
        }
        $this.AddCommandQueueItem(
            [pscustomobject]@{
                CommandName = 'Start'
            }
        )
        $this.Launch()
    }

    [void] Stop() {
        if ($false -eq $this.IsEnabled()) {
            [VRisingServerLog]::Error("[$($this._properties.ReadProperty('ShortName'))] cannot send Stop command - server is disabled")
            return
        }
        $this.AddCommandQueueItem(
            [pscustomobject]@{
                CommandName = 'Stop'
            }
        )
        $this.Launch()
    }

    [void] Enable() {
        $this.GetProcessMutex().WaitOne()
        try {
            $this._properties.WriteProperty('ProcessMonitorEnabled', $true)
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] server enabled")
        } finally {
            $this.GetProcessMutex().ReleaseMutex()
        }
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

    [void] Kill([bool]$force) {
        if ($false -eq $this.IsRunning()) {
           return
        }
        if ($true -eq $force) {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] forcefully killing monitor process")
        } else {
            [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] gracefully killing monitor process")
        }
        & taskkill.exe '/PID' $this._properties.ReadProperty('ProcessMonitorProcessId') $(if ($true -eq $force) { '/F' })
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

    # start the background process
    hidden [void] Launch() {
        # check before locking the mutex (so we don't unnecessarily block the thread)
        if ($true -eq $this.IsRunning()) {
            return
        }
        $this.GetProcessMutex().WaitOne()
        try {
            # check again just in case it was launched between checking the last statement and locking the mutex
            if ($true -eq $this.IsRunning()) {
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
            $process = Start-Process `
                -FilePath 'powershell' `
                -ArgumentList "-Command & { `$ErrorActionPreference = 'Stop'; `$server = Get-VRisingServer -ShortName '$($properties.shortName)'; `$server._processMonitor.Run(); }" `
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

    [bool] IsEnabled() {
        return $this._properties.ReadProperty('ProcessMonitorEnabled') -eq $true
    }

    hidden [bool] IsRunning() {
        return $this.ProcessIsRunning($this.GetMonitorProcess())
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
