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

# Load Flags
$script:VRisingServerManagerFlags = LoadServerManagerFlags

# Optionally Enable Log Timestamps
if ($true -eq $script:VRisingServerManagerFlags.ShowDateTime) {
    [VRisingServerLog]::ShowDateTime = $true
}

# Get Module Version
$script:ModuleVersion = (Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'VRisingServerManager.psd1')).ModuleVersion
[VRisingServerLog]::Info("VRisingServerManager v$ModuleVersion")

# List Flags
$enabledFlags = $script:VRisingServerManagerFlags.GetEnumerator() | Where-Object { $_.Value -eq $true } | Select-Object -ExpandProperty Name
if ($enabledFlags.Count -gt 0) {
    [VRisingServerLog]::Info("Using VRisingServerManagerFlags: $enabledFlags")
}

# check for new version
$skipNewVersionCheck = [VRisingServer]::GetConfigValue('SkipNewVersionCheck')
if (($true -ne $script:VRisingServerManagerFlags.SkipNewVersionCheck) -and
        ($true -ne $skipNewVersionCheck)) {
    $private:latestModule = Find-Module `
        -Name 'VRisingServerManager' `
        -Repository PSGallery `
        -MinimumVersion $ModuleVersion
    if ($ModuleVersion -ne $private:latestModule.Version) {
        $releaseNotesList = $private:latestModule.ReleaseNotes.Split(@("`r`n", "`r", "`n"), [System.StringSplitOptions]::None)
        [VRisingServerLog]::Warning('-- New Version Available! --')
        [VRisingServerLog]::Warning('')
        [VRisingServerLog]::Warning("Current Version: $ModuleVersion")
        [VRisingServerLog]::Warning(" Latest Version: $($private:latestModule.Version)")
        [VRisingServerLog]::Warning('')
        [VRisingServerLog]::Warning('To upgrade:')
        [VRisingServerLog]::Warning('  1. Stop all active monitors')
        [VRisingServerLog]::Warning('       run: vrdisable')
        [VRisingServerLog]::Warning("  2. Wait for monitors to stop and become 'Disabled'")
        [VRisingServerLog]::Warning('       run: vrget')
        [VRisingServerLog]::Warning("  3. Update the module")
        [VRisingServerLog]::Warning('       run: Update-Module -Name VRisingServerManager')
        [VRisingServerLog]::Warning("  4. Exit the current PowerShell session")
        [VRisingServerLog]::Warning("  5. Start a new PowerShell session")
        [VRisingServerLog]::Warning("  6. Import the module")
        [VRisingServerLog]::Warning('       run: Import-Module VRisingServerManager')
        [VRisingServerLog]::Warning("  7. Re-Enable all monitors")
        [VRisingServerLog]::Warning('       run: vrenable')
        [VRisingServerLog]::Warning('')
        [VRisingServerLog]::Warning('To disable checking for new versions, run:')
        [VRisingServerLog]::Warning('  vrmset SkipNewVersionCheck $true')
        [VRisingServerLog]::Warning('')
        [VRisingServerLog]::Warning("-- Release Notes --")
        [VRisingServerLog]::Warning($releaseNotesList)
    } else {
        [VRisingServerLog]::Info("You are using the latest version -- run: `'vrmset SkipNewVersionCheck `$true' to disable checking for new versions")
    }
} else {
    [VRisingServerLog]::Info("Skipped new version check -- run: `'vrmset SkipNewVersionCheck `$false' to enable checking for new versions")
}
