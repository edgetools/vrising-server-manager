function LoadServerManagerFlags {
    # had to stash this behavior into a function to be able to suppress the global warning from PSScriptAnalyzer
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')]
    param()
    if ($null -eq $Global:VRisingServerManagerFlags) {
        return @{}
    } else {
        return $Global:VRisingServerManagerFlags
    }
}
