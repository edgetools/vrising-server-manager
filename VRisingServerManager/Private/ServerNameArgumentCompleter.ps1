function ServerNameArgumentCompleter {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    $serverRepository = Get-VRisingServerRepository
    if ($null -eq $serverRepository) {
        return
    }
    if (-Not $serverRepository.Exists()) {
        return
    }
    $serverNames = $serverRepository.GetNames($WordToComplete)
    $serverNames | ForEach-Object {
        [System.Management.Automation.CompletionResult]::New($_)
    }
}
