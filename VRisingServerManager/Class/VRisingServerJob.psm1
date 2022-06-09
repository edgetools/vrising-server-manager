class VRisingServerJob {
    [IAsyncResult] $StartJobHandle
    [IAsyncResult] $StopJobHandle
    [powershell] $PowerShell
    [psobject] $ReturnValue
    [System.Management.Automation.ErrorRecord[]] $Errors
    [scriptblock] $ScriptToRun

    VRisingServerJob() {
        Update-TypeData `
                -TypeName "VRisingServerJob" `
                -MemberName Running `
                -MemberType ScriptProperty `
                -Value {
                    if (($null -ne $this.StartJobHandle) -and ($false -eq $this.StartJobHandle.IsCompleted)) {
                        return $true
                    }
                    if (($null -ne $this.StopJobHandle) -and ($false -eq $this.StopJobHandle.IsCompleted)) {
                        return $true
                    }
                    return $false
                } `
                -Force
    }
}
