using module ..\Class\VRisingServer.psm1

function Read-VRisingServerLog {
    [CmdletBinding(DefaultParameterSetName='ByShortName')]
    param(
        [Parameter(Position=1, ParameterSetName='ByShortName')]
        [Parameter(Position=1, ParameterSetName='ByServer')]
        [VRisingServerLogType] $LogType = [VRisingServerLogType]::File,

        [Parameter(Position=0, ParameterSetName='ByShortName')]
        [string[]] $ShortName,

        [Parameter(Position=0, ParameterSetName='ByServer', ValueFromPipeline=$true)]
        [VRisingServer] $Server,

        [Parameter()]
        [Alias('Tail')]
        [int]$Last,

        [Parameter()]
        [switch]$Follow
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByShortName') {
            $servers = [VRisingServer]::FindServers($ShortName)
        } else {
            $servers = @($Server)
        }
        foreach ($serverItem in $servers) {
            $logFile = $serverItem.GetLogFilePath($LogType)
            if ($false -eq [string]::IsNullOrWhiteSpace($logFile)) {
                $shortName = $($serverItem.ReadProperty('ShortName'))
                $getContentParams = @{
                    LiteralPath = $logFile
                }
                if ($Last -gt 0) {
                    $getContentParams['Last'] = $Last
                }
                if ($true -eq $Follow) {
                    $getContentParams['Wait'] = $true
                    $keepFollowing = $true
                    while ($true -eq $keepFollowing) {
                        try {
                            Get-Content @getContentParams | ForEach-Object { "[$shortName] $_" }
                            $keepFollowing = $false
                        } catch [System.IO.FileNotFoundException],[System.Management.Automation.ItemNotFoundException] {
                            # allow following a log file that doesn't exist yet
                            # or that gets rotated out from under it while being watched
                            Start-Sleep -Seconds 1
                            continue
                        }
                    }
                } else {
                    Get-Content @getContentParams | ForEach-Object { "[$shortName] $_" }
                }
            }
        }
    }
}

Register-ArgumentCompleter -CommandName Read-VRisingServerLog -ParameterName ShortName -ScriptBlock $function:ServerShortNameArgumentCompleter
