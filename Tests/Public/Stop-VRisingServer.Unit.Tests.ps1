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
    Context 'and service is started' {
        It 'stops the service' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsRunning = $True
            # act
            Stop-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsRunning | Should -BeFalse
        }
    }

    Context 'and service is already stopped' {
        It 'leaves the service stopped' {
            # arrange
            $service_provider = [ServiceProviderInMemoryAdapter]::New()
            $service_provider.b_IsInstalled = $True
            $service_provider.b_IsRunning = $False
            # act
            Stop-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
            # assert
            $service_provider.b_IsRunning | Should -BeFalse
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
            Stop-VRisingServer `
                -Name 'Foo' `
                -ServiceProvider $service_provider
        } | Should -Throw "Service 'Foo' is not installed"
    }
}
