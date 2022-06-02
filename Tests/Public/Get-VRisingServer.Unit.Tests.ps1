using module ..\..\VRisingServerManager\Class\ServerRepositoryInMemoryAdapter.psm1
using module ..\..\VRisingServerManager\Class\ServiceProviderInMemoryAdapter.psm1
using module ..\..\VRisingServerManager\Class\VRisingServer.psm1

BeforeAll {
    . $PSScriptRoot\..\Helpers.ps1
    Initialize-DUTPesterConfig
    Import-DUTModule
}

AfterAll {
    Remove-DUTModule
}

Describe 'When server exists' {
    BeforeAll {
        # arrange
        $server_repository = [ServerRepositoryInMemoryAdapter]::New()
        $server_name = 'Foo'
        $service_name = 'V Rising Server (Foo)'
        $server_repository.Servers[$server_name] = @{
            Name = $server_name
            UpdateOnStartup = $True
            ServiceName = $service_name
        }

        $service_provider = [ServiceProviderInMemoryAdapter]::New()
        $service_provider.b_IsInstalled = $True
        $service_provider.b_IsRunning = $True
        $service_provider.b_IsEnabled = $True
    }

    It 'returns a VRisingServer' {
        # act
        $server = Get-VRisingServer `
            -Name $server_name `
            -ServerRepository $server_repository `
            -ServiceProvider $service_provider
        # assert
        $server | Should -Not -BeNullOrEmpty -ErrorAction Stop
        $server.GetType() | Should -Be 'VRisingServer'
    }

    It 'has all expected object properties' {
        # act
        $server = Get-VRisingServer `
            -Name $server_name `
            -ServerRepository $server_repository `
            -ServiceProvider $service_provider
        # assert
        $server.PSObject.Properties.Name | Should -Contain 'Name'
        $server.PSObject.Properties.Name | Should -Contain 'UpdateOnStartup'
        $server.PSObject.Properties.Name | Should -Contain 'ServiceName'
        $server.PSObject.Properties.Name | Should -Contain 'ServiceIsRunning'
        $server.PSObject.Properties.Name | Should -Contain 'ServiceIsInstalled'
        $server.PSObject.Properties.Name | Should -Contain 'ServiceIsEnabled'
    }

    It 'loads values from the server repository' {
        # act
        $server = Get-VRisingServer `
            -Name $server_name `
            -ServerRepository $server_repository `
            -ServiceProvider $service_provider
        # assert
        $server.Name | Should -Be $server_name
        $server.UpdateOnStartup | Should -BeTrue
        $server.ServiceName | Should -Be $service_name
    }

    It 'loads service status from the provider' {
        # act
        $server = Get-VRisingServer `
            -Name $server_name `
            -ServerRepository $server_repository `
            -ServiceProvider $service_provider
        # assert
        $server.ServiceIsInstalled | Should -BeTrue
        $server.ServiceIsRunning | Should -BeTrue
        $server.ServiceIsEnabled | Should -BeTrue
    }
}
