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
    Context 'and service is enabled' {
        It 'disables the service' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsEnabled = $True
            # act
            Disable-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsEnabled | Should -BeFalse
        }
    }

    Context 'and service is already disabled' {
        It 'leaves the service disabled' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsEnabled = $False
            # act
            Disable-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsEnabled | Should -BeFalse
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
            Disable-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
        } | Should -Throw "Service 'Foo' is not installed"
    }
}
