BeforeAll {
    . $PSScriptRoot\..\Helpers.ps1
    $module_path = Get-DUTModulePath
}

Describe 'When one server exists' {
    It 'returns the server object' {
        Write-Host 'Foo'
    }
}
