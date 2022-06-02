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
    It 'uninstalls the service' {
        # arrange
        $service_provider = [ServiceProviderInMemoryAdapter]::New()
        $service_provider.b_IsInstalled = $True
        # act
        Uninstall-VRisingServer `
            -Name 'Foo' `
            -ServiceProvider $service_provider
        # assert
        $service_provider.b_IsInstalled | Should -BeFalse
    }
}

Describe 'When service is already uninstalled' {
    It 'leaves the service uninstalled' {
        # arrange
        $service_provider = [ServiceProviderInMemoryAdapter]::New()
        $service_provider.b_IsInstalled = $False
        # act
        Uninstall-VRisingServer `
            -Name 'Foo' `
            -ServiceProvider $service_provider
        # assert
        $service_provider.b_IsInstalled | Should -BeFalse
    }
}
