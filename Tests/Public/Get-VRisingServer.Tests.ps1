BeforeAll {
    . $PSScriptRoot\..\Helpers.ps1
    $module_path = Get-DUTModulePath
    Import-Module $module_path -Force
}

Describe 'When server exists' {
    It 'returns the server object' {
        $server_data = @{
            UpdateOnStartup = $True
        }
        $server = Get-VRisingServer -VRisingServerData $server_data
        $server | Should -Not -BeNullOrEmpty -ErrorAction Stop
    }
}
