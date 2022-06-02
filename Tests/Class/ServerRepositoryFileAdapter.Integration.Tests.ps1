using module ..\..\VRisingServerManager\Class\ServerRepositoryFileAdapter.psm1

BeforeAll {
    . $PSScriptRoot\..\Helpers.ps1
    Initialize-DUTPesterConfig
}

Describe 'Load' {
    Context 'When server file exists' {
        It 'returns a VRisingServer' {
            # arrange
            New-Item -ItemType Directory -Path 'TestDrive:\Servers'
            $ServerRepository = [ServerRepositoryFileAdapter]::New('TestDrive:\Servers')
            @{
                Name = 'Foo'
                UpdateOnStartup = $True
            } | ConvertTo-Json | Out-File -LiteralPath 'TestDrive:\Servers\Foo.json'
            # act
            $Server = $ServerRepository.Load('Foo')
            # assert
            $Server | Should -Not -BeNullOrEmpty
            $Server.Name | Should -Be 'Foo'
            $Server.UpdateOnStartup | Should -BeTrue
        }
    }

    Context 'When server file does not exist' {
        It 'returns nothing' {
            # arrange
            $ServerRepository = [ServerRepositoryFileAdapter]::New("TestDrive:\Servers")
            # act
            $Server = $ServerRepository.Load('Foo')
            # assert
            $Server | Should -BeNullOrEmpty
        }
    }
}
