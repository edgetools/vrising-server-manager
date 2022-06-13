function ServerManagerOptionArgumentCompleter {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    $serverManagerOptions = [VRisingServer]::GetConfigKeys() -like "$WordToComplete*"
    foreach ($serverManagerOption in $serverManagerOptions) {
        [System.Management.Automation.CompletionResult]::New($serverManagerOption)
    }
}
