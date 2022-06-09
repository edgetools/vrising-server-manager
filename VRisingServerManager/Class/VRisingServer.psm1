using module ..\Class\VRisingServerJob.psm1
using module ..\Enum\VRisingServerStatus.psm1

class VRisingServer {
    [string] $Name
    [string] $SaveDir
    [string] $InstallDir
    [bool] $UpdateOnStartup

    [VRisingServerStatus] hidden $_status

    static VRisingServer() {
        Update-TypeData `
                -TypeName "VRisingServer" `
                -MemberName Status `
                -MemberType ScriptProperty `
                -Value { return $this.GetStatus(); } `
                -Force
    }

    VRisingServer() {
        $this._status = [VRisingServerStatus]::Stopped
    }

    [void] Start() {
        $this._powershell = [powershell]::Create()
        $this._powershell.AddScript({ Start-Sleep -Seconds 300 })
        $this._resultHandle = $this._powershell.BeginInvoke()
    }

    [void] Stop() {
        $this._result = $this._powershell.EndInvoke($this._job)
        $this._powershell.Runspace.Close()
    }

    [void] Restart() {}
    [void] Enable() {}
    [void] Disable() {}
    [void] Create() {}
    [void] Update() {}

    [VRisingServerStatus] hidden GetStatus() {
        # NotStarted
        # Running
        # Completed
        # Failed
        # Stopped
        # Blocked
        # Disconnected
        # Stopping
        # - Workflow Only (?):
        # Suspended
        # Suspending
        $stoppedStates = @(
            [System.Management.Automation.JobState]::NotStarted,
            [System.Management.Automation.JobState]::Completed,
            [System.Management.Automation.JobState]::Failed,
            [System.Management.Automation.JobState]::Stopped,
            [System.Management.Automation.JobState]::Blocked,
            [System.Management.Automation.JobState]::Disconnected
        )
        if ($null -eq $this._job) {
            return [VRisingServerStatus]::Stopped
        }
        $status = [VRisingServerStatus]::Stopped
        switch ($this._job.State) {
            {($_ -in $stoppedStates)} {
                $status = [VRisingServerStatus]::Stopped
                break
            }
            [System.Management.Automation.JobState]::Running {
                # need a way to determine if this is an upgrade job or not
                # or switch to using two separate job properties
                # e.g. _runJob and _updateJob
                $status = [VRisingServerStatus]::Running
                break
            }
            Default {
                $status = [VRisingServerStatus]::Stopped
                break
            }
        }
        return $status
    }
}
