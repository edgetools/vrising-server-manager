BeforeAll {
    . $PSScriptRoot\Helpers.ps1
    Initialize-DUTPesterConfig
    Import-DUTModule
}

Describe 'Getting a server' {
    It 'runs successfully' {
        Get-VRisingServer -Name 'Foo'
    }
}
