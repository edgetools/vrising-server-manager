function Set-VRisingServerManagerConfigOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Option,

        [Parameter(Position=1)]
        [psobject]$Value
    )
    [VRisingServer]::SetConfigValue($Option, $Value)
}

Register-ArgumentCompleter -CommandName Set-VRisingServerManagerConfigOption -ParameterName Option -ScriptBlock $function:ServerManagerOptionArgumentCompleter
