# run this command instead of VRisingServer.exe directly
# this will know how to save the lastexitcode when it exits

function Invoke-VRisingServer {
    param (
        [string]$ShortName,
        [string]$ExePath,
        [string]$DataDir,
        [string]$LogFile
    )

    Register-EngineEvent PowerShell.Exiting -Action {
        [VRisingServerLog]::Info("[!!!!] caught exiting event")
    }

    try {
        $server = Get-VRisingServer $ShortName
        [VRisingServerLog]::Info("[$shortName] starting server")
        & $ExePath -persistentDataPath $DataDir -logFile $LogFile
    } finally {
        $exitCode = $LastExitCode
        $server._properties.WriteProperty('LastExitCode', [int]$exitCode)
        if ($exitCode -ne 0) {
            [VRisingServerLog]::Error("[$shortName] server exited with code $($exitCode)")
        }
        [VRisingServerLog]::Info("[$shortName] server exited with code $($exitCode)")
    }
}

# -ArgumentList "-persistentDataPath `"$($properties.DataDir)`" -logFile `"$logFile`"" `
