function Uninstall-VRisingServerService {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High', DefaultParameterSetName='ByServerName')]
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
        $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
        if ($null -eq $Service) {
            throw "Service '$ServiceName' not found"
        }
        if ($PSCmdlet.ShouldProcess($ServiceName)) {
            $DeleteResponse = $Service.Delete()
            if (($null -eq $DeleteResponse) -or ($DeleteResponse.ReturnValue -ne 0)) {
                Write-Output $DeleteResponse
                throw "Error occurred while attempting to delete service '$ServiceName'"
            }
        }
        Write-Host "Service '$ServiceName' uninstalled"
    }
}

Register-ArgumentCompleter -CommandName Uninstall-VRisingServerService -ParameterName ServerName -ScriptBlock $function:ServerNameArgumentCompleter
