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
    Context 'and service is disabled' {
        It 'enables the service' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsEnabled = $False
            # act
            Enable-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsEnabled | Should -BeTrue
        }
    }

    Context 'and service is already enabled' {
        It 'leaves the service enabled' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsEnabled = $True
            # act
            Enable-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsEnabled | Should -BeTrue
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
            Enable-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
        } | Should -Throw "Service 'Foo' is not installed"
    }
}
