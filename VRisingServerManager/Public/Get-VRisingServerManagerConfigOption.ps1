function Get-VRisingServerManagerConfigOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Option
    )
    [VRisingServer]::GetConfigValue($Option)
}

Register-ArgumentCompleter -CommandName Get-VRisingServerManagerConfigOption -ParameterName Option -ScriptBlock $function:ServerManagerOptionArgumentCompleter
