function New-VRisingServer {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ShortName,

        [Parameter()]
        [string] $ServersDir = [VRisingServer]::GetDefaultServersDir(),

        [Parameter()]
        [string] $DataDir,

        [Parameter()]
        [string] $InstallDir,

        [Parameter()]
        [string] $LogDir
    )

    function ReadPathOrUseDefault([string]$name, [string]$default) {
        $inputString = Read-Host -Prompt "Specify $name path or press Enter to accept default [$default]"
        if ($false -eq [string]::IsNullOrWhiteSpace($inputString)) {
            return $inputString
        } else {
            return $default
        }
    }

    if ([string]::IsNullOrWhiteSpace($DataDir)) {
        $defaultDataDir = Join-Path -Path $ServersDir -ChildPath $shortName |
            Join-Path -ChildPath ([VRisingServer]::DATA_DIR_NAME)
        $DataDir = ReadPathOrUseDefault 'DataDir' $defaultDataDir
    }
    if ([string]::IsNullOrWhiteSpace($InstallDir)) {
        $defaultInstallDir = Join-Path -Path $ServersDir -ChildPath $shortName |
            Join-Path -ChildPath ([VRisingServer]::INSTALL_DIR_NAME)
        $InstallDir = ReadPathOrUseDefault 'InstallDir' $defaultInstallDir
    }
    if ([string]::IsNullOrWhiteSpace($LogDir)) {
        $defaultLogDir = Join-Path -Path $ServersDir -ChildPath $shortName |
            Join-Path -ChildPath ([VRisingServer]::LOG_DIR_NAME)
        $LogDir = ReadPathOrUseDefault 'LogDir' $defaultLogDir
    }

    if ($true -eq $PSCmdlet.ShouldProcess($ShortName)) {
        [VRisingServer]::CreateServer($ShortName, $DataDir, $InstallDir, $LogDir)
    }
}
