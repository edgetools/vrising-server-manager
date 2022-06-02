using module ..\..\VRisingServerManager\Class\ServiceProviderInMemoryAdapter.psm1

BeforeAll {
    . $PSScriptRoot\..\Helpers.ps1
    Initialize-DUTPesterConfig
    Import-DUTModule
}

AfterAll {
    Remove-DUTModule
}

Describe 'When service is not installed' {
    It 'installs the service' {
        # arrange
        $service_provider = [ServiceProviderInMemoryAdapter]::New()
        $service_provider.b_IsInstalled = $False
        # act
        Install-VRisingServer `
            -Name 'Foo' `
            -ServiceProvider $service_provider
        # assert
        $service_provider.b_IsInstalled | Should -BeTrue
    }
}

Describe 'When service is already installed' {
    It 'leaves the service installed' {
        # arrange
        $service_provider = [ServiceProviderInMemoryAdapter]::New()
        $service_provider.b_IsInstalled = $True
        # act
        Install-VRisingServer `
            -Name 'Foo' `
            -ServiceProvider $service_provider
        # assert
        $service_provider.b_IsInstalled | Should -BeTrue
    }
}
