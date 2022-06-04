function Set-VRisingServerContext {
    param (
        [Parameter(Position=0)]
        [string] $ShortName,

        [Parameter()]
        [string] $ServerConfigDirPath = $script:ActiveServerConfigDirPath
    )
    $script:ActiveServerShortName = $ShortName
    Write-Host "Server Context changed to: $ShortName"
}

Register-ArgumentCompleter -CommandName Set-VRisingServerContext -ParameterName ShortName -ScriptBlock $function:ServerNameArgumentCompleter
