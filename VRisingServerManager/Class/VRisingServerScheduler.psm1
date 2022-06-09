using module .\VRisingServerJob.psm1

# start/stop using the scheduler
# the scheduler will run its own jobs thread which will check on any running servers
# and dispose of their runspaces when they die
# and extract execution data

# use a single-thread apartment? - what is the default
# use ReuseThread

# will run a thread loop and check on all the servers

class VRisingServerScheduler {
    [hashtable] hidden $_workerJobs
    [hashtable] hidden $_workerFlags
    [System.Collections.ArrayList] hidden $_runningWorkerJobs
    [runspace] hidden $_runspace
    [powershell] hidden $_powershell
    [IAsyncResult] hidden $_resultHandle

    static VRisingServerScheduler() {
        Update-TypeData `
                -TypeName "VRisingServerScheduler" `
                -MemberName Running `
                -MemberType ScriptProperty `
                -Value { return $this.ThreadRunning($this._resultHandle); } `
                -Force
        Update-TypeData `
                -TypeName "VRisingServerScheduler" `
                -MemberName PollingRate `
                -MemberType ScriptProperty `
                -Value { return $this._workerFlags.PollingRate; } `
                -SecondValue { param($value) $this._workerFlags.PollingRate = $value; } `
                -Force
        Update-TypeData `
                -TypeName "VRisingServerScheduler" `
                -MemberName JobCount `
                -MemberType ScriptProperty `
                -Value { return $this._runningWorkerJobs.Count; } `
                -Force
    }

    VRisingServerScheduler() {
        $this._workerJobs = @{}
        $this._workerFlags = [hashtable]::Synchronized(@{
            PollingRate = 5
            Run = $false
        })
        $this._runningWorkerJobs = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::New())
    }

    [VRisingServerJob] GetJob([string]$name) {
        return $this._workerJobs[$name]
    }

    [void] StartJob([VRisingServerJob]$serverJob) {
        if (($null -ne $serverJob.StartJobHandle) -and ($true -eq $this.ThreadRunning($serverJob.StartJobHandle))) {
            throw 'job is already running'
        }
        if (($null -ne $serverJob.StopJobHandle) -and ($true -eq $this.ThreadRunning($serverJob.StopJobHandle))) {
            throw 'job is currently stopping'
        }
        if ($null -eq $serverJob.ScriptToRun) {
            throw 'job ScriptToRun cannot be null'
        }
        if ($null -ne $serverJob.PowerShell) {
            throw 'job powershell instance must be null before starting'
        }
        $serverJob.PowerShell = [powershell]::Create()
        $serverJob.PowerShell.Runspace.Name = "VRisingServer$($serverJob.PowerShell.Runspace.Id)"
        $serverJob.PowerShell.AddScript($serverJob.ScriptToRun)
        $serverJob.Errors = $null
        $serverJob.ReturnValue = $null
        $serverJob.StopJobHandle = $null
        $serverJob.StartJobHandle = $serverJob.PowerShell.BeginInvoke()
        $this._runningWorkerJobs.Add($serverJob)
    }

    [void] StopJob([VRisingServerJob]$serverJob) {
        if (($null -eq $serverJob.StartJobHandle) -or ($false -eq $this.ThreadRunning($serverJob.StartJobHandle))) {
            throw 'job is already stopped'
        }
        if (($null -ne $serverJob.StopJobHandle) -and ($true -eq $this.ThreadRunning($serverJob.StopJobHandle))) {
            throw 'job is already stopping'
        }
        if ($null -eq $serverJob.PowerShell) {
            throw 'job powershell instance cannot be null before stopping'
        }
        $serverJob.StopJobHandle = $serverJob.PowerShell.BeginStop($null, $null)
    }

    [bool] hidden ThreadRunning($resultHandle) {
        if ($null -ne $resultHandle) {
            if ($resultHandle.IsCompleted -eq $false) {
                return $true
            } elseif ($resultHandle.IsCompleted -eq $true) {
                return $false
            }
        }
        return $false
    }

    [void] hidden StartWorkerThread() {
        if (($null -ne $this._resultHandle) -and ($true -eq $this.ThreadRunning($this._resultHandle))) {
            throw 'scheduler thread is already running'
        }
        if ($null -ne $this._runspace) {
            throw 'scheduler runspace instance must be null before starting'
        }
        if ($null -ne $this._powershell) {
            throw 'scheduler powershell instance must be null before starting'
        }
        $this._runspace = [runspacefactory]::CreateRunspace()
        $this._runspace.ApartmentState = 'STA'
        $this._runspace.ThreadOptions = 'ReuseThread'
        $this._runspace.Name = 'VRisingServerScheduler'
        $this._runspace.Open()
        $this._runspace.SessionStateProxy.SetVariable('workerFlags', $this._workerFlags)
        $this._runspace.SessionStateProxy.SetVariable('workerJobs', $this._runningWorkerJobs)
        $workerScript = {
            while ($workerFlags.Run -eq $true) {
                for ($i = $workerJobs.Count - 1; $i -ge 0; $i--) {
                    $currentJob = $workerJobs[$i]
                    $cleanUpPowerShell = $false
                    # check if this job was just forcefully stopped
                    if (($null -ne $currentJob.StopJobHandle) -and ($true -eq $currentJob.StopJobHandle.IsCompleted)) {
                        $currentJob.StopJobHandle.AsyncWaitHandle.Dispose()
                        $currentJob.StopJobHandle = $null
                        $cleanUpPowerShell = $true
                    }
                    # check if there's anything to receive
                    if (($null -ne $currentJob.StartJobHandle) -and ($true -eq $currentJob.StartJobHandle.IsCompleted)) {
                        $currentJob.ReturnValue = $currentJob.PowerShell.EndInvoke($currentJob.StartJobHandle)
                        $currentJob.StartJobHandle.AsyncWaitHandle.Dispose()
                        $currentJob.StartJobHandle = $null
                        $cleanUpPowerShell = $true
                    }
                    # clean powershell up and remove the job from the list
                    if ($true -eq $cleanUpPowerShell) {
                        if ($true -eq $currentJob.PowerShell.HadErrors) {
                            $currentJob.Errors = $currentJob.PowerShell.Streams.Error
                        }
                        $currentJob.PowerShell.Dispose()
                        $currentJob.PowerShell = $null
                        $workerJobs.Remove($currentJob)
                    }
                }
                Start-Sleep -Seconds $workerFlags.PollingRate
            }
        }
        $this._powershell = [powershell]::Create()
        $this._powershell.Runspace = $this._runspace
        $this._powershell.AddScript($workerScript)
        $this._workerFlags.Run = $true
        $this._resultHandle = $this._powershell.BeginInvoke()
    }

    [psobject] hidden StopWorkerThread() {
        $this._workerFlags.Run = $false
        $returnValue = $null
        if ($null -ne $this._powershell) {
            if ($null -ne $this._resultHandle) {
                $returnValue = $this._powershell.EndInvoke($this._resultHandle)
            }
        }
        if ($null -ne $this._resultHandle) {
            $this._resultHandle.AsyncWaitHandle.Dispose()
        }
        if ($null -ne $this._powershell) {
            $this._powershell.Dispose()
        }
        if ($null -ne $this._runspace) {
            $this._runspace.Dispose()
        }
        $this._powershell = $null
        $this._runspace = $null
        $this._resultHandle = $null
        return $returnValue
    }
}
