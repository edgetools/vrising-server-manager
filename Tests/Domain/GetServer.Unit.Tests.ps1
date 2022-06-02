using module ..\..\VRisingServerManager\Class\ServerRepositoryInMemoryAdapter.psm1
using module ..\..\VRisingServerManager\Class\ServiceProviderInMemoryAdapter.psm1

BeforeAll {
    . $PSScriptRoot\..\..\VRisingServerManager\Domain\GetServer.ps1
    . $PSScriptRoot\..\..\VRisingServerManager\Domain\CreateServer.ps1
}

Describe 'GetServer' {
    Context 'When server exists' {
        BeforeEach {
            $ServerRepository = [ServerRepositoryInMemoryAdapter]::New()
            $ServiceProvider = [ServiceProviderInMemoryAdapter]::New()
            CreateServer `
                -ServerName 'FooServer' `
                -ServiceName 'FooService' `
                -ServerRepository $ServerRepository `
                -ServiceProvider $ServiceProvider
            $ServiceRepository.Enable('FooService')
        }

        It 'loads the server from the repository' {
            # act
            $Server = GetServer `
                -Name 'FooServer' `
                -ServerRepository $ServerRepository `
                -ServiceProvider $ServiceProvider
            # assert
            $Server | Should -Not -BeNullOrEmpty
            $Server.GetType() | Should -Be 'VRisingServer'
            $Server.UpdateOnStartup | Should -BeTrue
        }

        It 'loads the service from the provider' {
            # act
            $Server = GetServer `
                -Name 'FooServer' `
                -ServerRepository $ServerRepository `
                -ServiceProvider $ServiceProvider
            # assert
            $Server.ServiceName | Should -Be 'FooService'
        }
    }
}
