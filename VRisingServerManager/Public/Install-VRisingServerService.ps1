function Install-VRisingServerService {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ByServerName')]
    param(
        [Parameter(ParameterSetName='ByServerName', Position=0)]
        [string] $ServerName = $script:ActiveServerShortName,

        [Parameter(ParameterSetName='ByServerName')]
        [string] $ServerConfigDirPath = $script:ActiveServerConfigDirPath,

        [Parameter(ValueFromPipelineByPropertyName, Mandatory=$true, ParameterSetName='ByServiceName')]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceName,

        [Parameter()]
        [switch] $Force
    )

    begin {
        if ($Force){
            $ConfirmPreference = 'None'
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByServerName') {
            $Server = Get-VRisingServer -ShortName $ServerName
            $ServiceName = $Server.ServiceName
        }
        try {
            if ($PSCmdlet.ShouldProcess($ServiceName)) {
                # "`"$PowerShellPath`" -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command { while ($true) { Write-Host 'Sleeping...'; Start-Sleep -Seconds 1; } }"
                New-Service `
                    -Name $ServiceName `
                    -BinaryPathName "`"$PowerShellPath`" -NonInteractive -NoProfile -ExecutionPolicy Bypass" `
                    | Out-Null
            }
        } catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
            if ($_.FullyQualifiedErrorId -eq 'CouldNotNewService,Microsoft.PowerShell.Commands.NewServiceCommand') {
                $_.ErrorDetails = "Service '$ServiceName' already exists"
            }
            throw $_
        }
        Write-Host "Service '$ServiceName' installed"
    }
}

Register-ArgumentCompleter -CommandName Install-VRisingServerService -ParameterName ServerName -ScriptBlock $function:ServerNameArgumentCompleter
