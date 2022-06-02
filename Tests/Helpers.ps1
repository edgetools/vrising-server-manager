
function Initialize-DUTPesterConfig {
    if ($null -eq $PesterPreference) {
        $PesterPreference = [PesterConfiguration]::Default
    }
    $PesterPreference.Should.ErrorAction = 'Continue'
}

function Get-DUTModulePath {
    Resolve-Path $PSScriptRoot\..\VRisingServerManager
}

function Import-DUTModule {
    Import-Module (Get-DUTModulePath) -Force
}

function Remove-DUTModule {
    Remove-Module VRisingServerManager -Force
}

function Get-DUTModuleName {
    'VRisingServerManager'
}
