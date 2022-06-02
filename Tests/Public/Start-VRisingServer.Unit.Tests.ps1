using module ..\..\VRisingServerManager\Class\ServiceProviderInMemoryAdapter.psm1

BeforeAll {
    . $PSScriptRoot\..\Helpers.ps1
    Initialize-DUTPesterConfig
    Import-DUTModule
}

AfterAll {
    Remove-DUTModule
}

Describe 'When service is installed' {
    Context 'and service is stopped' {
        It 'starts the service' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsRunning = $False
            # act
            Start-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsRunning | Should -BeTrue
        }
    }

    Context 'and service is already started' {
        It 'leaves the service running' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsRunning = $True
            # act
            Start-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsRunning | Should -BeTrue
        }
    }
}

Describe 'When service is not installed' {
    It 'returns an error' {
        # arrange
        $service_provider = [ServiceProviderInMemoryAdapter]::New()
        $service_provider.b_IsInstalled = $False
        # act & assert
        {
            Start-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
        } | Should -Throw "Service 'Foo' is not installed"
    }
}
