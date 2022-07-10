function Set-VRisingServerManagerConfigOption {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Option,

        [Parameter(Position=1)]
        [psobject]$Value
    )
    if ($PSCmdlet.ShouldProcess($Option)) {
        [VRisingServer]::SetConfigValue($Option, $Value)
    }
}

Register-ArgumentCompleter -CommandName Set-VRisingServerManagerConfigOption -ParameterName Option -ScriptBlock $function:ServerManagerOptionArgumentCompleter
