BeforeAll {
    $module_test_file = (Get-Item $PSCommandPath)
    $module_name = $module_test_file.Name.Remove($module_test_file.Name.Length-$('.Tests.ps1'.Length))
    $module_dir = Resolve-Path $PSScriptRoot\..\$module_name
}

Describe 'Importing the Module' {
    It 'Imports the Module successfully' {
        Import-Module $module_dir -Force
    }
}
