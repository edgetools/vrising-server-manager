BeforeAll {
    . $PSScriptRoot\Helpers.ps1
    $module_path = Get-DUTModulePath
}

Describe 'When importing the module' {
    It 'imports the Module successfully' {
        Import-Module $module_path -Force
    }
}
