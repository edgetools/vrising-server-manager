function ServerShortNameArgumentCompleter {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    $serverShortNames = [VRisingServer]::GetShortNames() -like "$WordToComplete*"
    foreach ($serverShortName in $serverShortNames) {
        [System.Management.Automation.CompletionResult]::New($serverShortName)
    }
}
