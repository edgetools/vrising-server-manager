using module ..\..\VRisingServerManager\Class\ServiceProviderWindowsAdapter.psm1

Describe 'IsInstalled' {
    BeforeEach {
        $ReservedName_TempFile = New-TemporaryFile
        $ReservedName = $ReservedName_TempFile.BaseName
        $ServiceName = "V Rising Server ($ReservedName)"
    }

    AfterEach {
        if (Test-Path -LiteralPath $ReservedName_TempFile.FullName -PathType Leaf) {
            Remove-Item $ReservedName_TempFile
        }
    }

    Context 'When service is not installed' {
        It 'returns False' {
            # arrange
            $ServiceProvider = [ServiceProviderWindowsAdapter]::New($ServiceName)
            # act & assert
            $ServiceProvider.IsInstalled() | Should -Be $False
        }
    }

    Context 'When service is installed' {
        It 'returns True' {
            # arrange
            $ServiceProvider = [ServiceProviderWindowsAdapter]::New($ServiceName)
            # $ServiceProvider.Install()
            # act & assert
            $ServiceProvider.IsInstalled() | Should -Be $True
        }
    }
}

Describe 'Install' {
    BeforeEach {
        $ReservedName_TempFile = New-TemporaryFile
        $ReservedName = $ReservedName_TempFile.BaseName
        $ServiceName = "V Rising Server ($ReservedName)"
    }

    AfterEach {
        $ServiceProvider.Uninstall()
        if (Test-Path -LiteralPath $ReservedName_TempFile.FullName -PathType Leaf) {
            Remove-Item $ReservedName_TempFile
        }
    }

    Context 'When the service is not yet installed' {
        It 'installs the service' {
            # arrange
            $ServiceProvider = [ServiceProviderWindowsAdapter]::New($ServiceName)
            # act
            $ServiceProvider.Install()
            # assert
            $ServiceProvider.IsInstalled() | Should -BeTrue
        }
    }

    Context 'When the service is already installed' {
        It 'leaves the service installed' {
            # arrange
            $ServiceProvider = [ServiceProviderWindowsAdapter]::New($ServiceName)
            $ServiceProvider.Install()
            # act
            $ServiceProvider.Install()
            # assert
            $ServiceProvider.IsInstalled() | Should -BeTrue
        }
    }
}

Describe 'Uninstall' {
    BeforeEach {
        $ReservedName_TempFile = New-TemporaryFile
        $ReservedName = $ReservedName_TempFile.BaseName
        $ServiceName = "V Rising Server ($ReservedName)"
    }

    AfterEach {
        $ServiceProvider.Uninstall()
        if (Test-Path -LiteralPath $ReservedName_TempFile.FullName -PathType Leaf) {
            Remove-Item $ReservedName_TempFile
        }
    }

    Context 'When the service is currently installed' {
        It 'uninstalls the service' {
            # arrange
            $ServiceProvider = [ServiceProviderWindowsAdapter]::New($ServiceName)
            $ServiceProvider.Install()
            # act
            $ServiceProvider.Uninstall()
            # assert
            $ServiceProvider.IsInstalled() | Should -BeFalse
        }
    }

    Context 'When the service is already uninstalled' {
        It 'leaves the service uninstalled' {
            # arrange
            $ServiceProvider = [ServiceProviderWindowsAdapter]::New($ServiceName)
            # act
            $ServiceProvider.Uninstall()
            # assert
            $ServiceProvider.IsInstalled() | Should -BeFalse
        }
    }
}
