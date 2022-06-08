function ServerNameArgumentCompleter {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    if ($null -ne $FakeBoundParameters['ServerRepository']) {
        $serverRepository = $FakeBoundParameters['ServerRepository']
    } else {
        $serverRepository = Get-VRisingServerRepository
    }
    if ($null -eq $serverRepository) {
        return
    }
    $serverNames = $serverRepository.GetNames("$WordToComplete*")
    foreach ($serverName in $serverNames) {
        [System.Management.Automation.CompletionResult]::New($serverName)
    }
}
