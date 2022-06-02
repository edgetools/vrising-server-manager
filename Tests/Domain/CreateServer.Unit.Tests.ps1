using module ..\..\VRisingServerManager\Class\ServerRepositoryInMemoryAdapter.psm1
using module ..\..\VRisingServerManager\Class\ServiceProviderInMemoryAdapter.psm1

BeforeAll {
    . $PSScriptRoot\..\..\VRisingServerManager\Domain\CreateServer.ps1
}

Describe 'CreateServer' {
    Context 'When server does not exist' {
        BeforeEach {
            $ServerRepository = [ServerRepositoryInMemoryAdapter]::New()
            $ServiceProvider = [ServiceProviderInMemoryAdapter]::New()
        }

        It 'installs the service' {
            # act
            CreateServer `
                -ServerName 'FooServer' `
                -ServiceName 'FooService' `
                -ServerRepository $ServerRepository `
                -ServiceProvider $ServiceProvider
            # assert
            $ServiceProvider.IsInstalled('FooService') | Should -BeTrue
        }

        It 'saves the server to the repository' {
            # act
            CreateServer `
                -ServerName 'FooServer' `
                -ServiceName 'FooService' `
                -ServerRepository $ServerRepository `
                -ServiceProvider $ServiceProvider
            # assert
            $ServerRepository.Servers['FooServer'] | Should -Not -BeNullOrEmpty
        }
    }
}
