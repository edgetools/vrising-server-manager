ExportAliases

$Global:PSDefaultParameterValues['Start-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Stop-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Update-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Remove-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Enable-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Disable-VRisingServer:ErrorAction'] = 'Continue'
$Global:PSDefaultParameterValues['Restart-VRisingServer:ErrorAction'] = 'Continue'

# custom formatters
Update-FormatData -AppendPath "$PSScriptRoot\VRisingServerManager.Format.ps1xml"

# check for new version
if ('SkipNewVersionCheck' -notin $VRisingServerManagerFlags) {
    $private:latestModule = Find-Module `
        -Name 'VRisingServerManager' `
        -Repository PSGallery `
        -MinimumVersion $ModuleVersion
    if ($ModuleVersion -ne $private:latestModule.Version) {
        $releaseNotesWarning = ($private:latestModule.ReleaseNotes.Split(@("`r`n", "`r", "`n"), [System.StringSplitOptions]::None) |
            ForEach-Object { "WARNING: $_" }) -join ([System.Environment]::NewLine)
        Write-Warning "-- New Version Available! --"
        Write-Warning ''
        Write-Warning "Current Version: $ModuleVersion"
        Write-Warning "Latest Version: $($private:latestModule.Version)"
        Write-Warning ''
        Write-Warning "To update, run:"
        Write-Warning "  Update-Module -Name VRisingServerManager"
        Write-Warning ''
        Write-Warning "To disable this check:"
        Write-Warning "  `$VRisingServerManagerFlags += ('SkipNewVersionCheck')"
        Write-Warning ''
        Write-Warning "-- Release Notes --$([System.Environment]::NewLine)$($releaseNotesWarning)"
    }
}
