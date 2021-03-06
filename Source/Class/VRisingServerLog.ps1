class VRisingServerLog {
    static [bool] $ShowDateTime = $false

    static [void] Info([PSCustomObject[]]$toLog) {
        $toLog | ForEach-Object { Write-Information $([VRisingServerLog]::WithPrefix($_)) -InformationAction 'Continue' }
    }

    static [void] Verbose([PSCustomObject[]]$toLog) {
        $toLog | ForEach-Object { Write-Verbose $([VRisingServerLog]::WithPrefix($_)) }
    }

    static [void] Debug([PSCustomObject[]]$toLog) {
        $toLog | ForEach-Object { Write-Debug $([VRisingServerLog]::WithPrefix($_)) }
    }

    static [void] Warning([PSCustomObject[]]$toLog) {
        $toLog | ForEach-Object { Write-Warning $([VRisingServerLog]::WithPrefix($_)) }
    }

    static [void] Error([PSCustomObject[]]$toLog) {
        $toLog | ForEach-Object { Write-Error $([VRisingServerLog]::WithPrefix($_)) }
    }

    static [string[]] FormatError([System.Management.Automation.ErrorRecord]$errorRecord) {
        $output = [System.Collections.ArrayList]::New()
        $output.AddRange($errorRecord.Exception.ToString() -split ([System.Environment]::NewLine))
        $output.AddRange($errorRecord.InvocationInfo.PositionMessage -split ([System.Environment]::NewLine))
        $output.AddRange($errorRecord.ScriptStackTrace -split ([System.Environment]::NewLine))
        return $output.ToArray([string])
    }

    static hidden [string] WithPrefix([PSCustomObject]$toLog) {
        $prefixString = ''
        if ($true -eq [VRisingServerLog]::ShowDateTime) {
            $prefixString += Get-Date -Format '[yyyy-MM-dd HH:mm:ss] '
        }
        $prefixString += '(VRisingServer) '
        $prefixString += $toLog.ToString()
        return $prefixString
    }
}
