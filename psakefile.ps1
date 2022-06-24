properties {
    $moduleVersion = $env:MODULE_BUILD_VERSION
    $moduleFilePath = "$PSScriptRoot\VRisingServerManager\VRisingServerManager.psm1"
    $moduleManifestFilePath = "$PSScriptRoot\VRisingServerManager\VRisingServerManager.psd1"
    $moduleDirPath = "$PSScriptRoot\VRisingServerManager"

    $moduleFragmentDirPath = "$PSScriptRoot\Source\Module"
    $classFragmentDirPath = "$PSScriptRoot\Source\Class"
    $privateFragmentDirPath = "$PSScriptRoot\Source\Private"
    $publicFragmentDirPath = "$PSScriptRoot\Source\Public"
    $fragmentBuildOrder = @($classFragmentDirPath, $privateFragmentDirPath, $publicFragmentDirPath)

    $packageFilesDirPath = "$PSScriptRoot\Package"

    $licenseFilePath = "$PSScriptRoot\LICENSE.txt"
}

Task default -Depends Clean, Build

Task Clean {
    if ($true -eq (Test-Path -LiteralPath $moduleDirPath -PathType Container)) {
        Remove-Item -LiteralPath $moduleDirPath -Recurse
    }
}

Task Build -Depends EnsureModuleDirExists, CombineSourceFragments, CopyPackageFiles, CopyLicenseFile, SetModuleVersion

Task EnsureModuleDirExists {
    if ($false -eq (Test-Path -LiteralPath $moduleDirPath -PathType Container)) {
        New-Item -Path $moduleDirPath -ItemType Directory | Out-Null
    }
}

Task CombineSourceFragments {
    $moduleFile = Get-Content -Path "$moduleFragmentDirPath\header.ps1" -Raw

    foreach ($fragmentDirPath in $fragmentBuildOrder) {
        $fragmentFiles = Get-ChildItem -Path "$fragmentDirPath\*.ps1" -File
        foreach ($fragmentFile in $fragmentFiles) {
            $moduleFile += "`n"
            $moduleFile += Get-Content -LiteralPath $fragmentFile.FullName -Raw
        }
    }

    $moduleFile += "`n"
    $moduleFile += Get-Content -Path "$moduleFragmentDirPath\footer.ps1" -Raw

    $moduleFile | Out-File -LiteralPath $moduleFilePath
}

Task CopyPackageFiles {
    Copy-Item -Path "$packageFilesDirPath\*" -Destination $moduleDirPath -Recurse
}

Task CopyLicenseFile {
    Copy-Item -Path $licenseFilePath -Destination $moduleDirPath
}

Task SetModuleVersion {
    $versionToUse = $null
    if ($false -eq [string]::IsNullOrWhiteSpace($moduleVersion)) {
        $versionToUse = $moduleVersion
    }
    if ($null -ne $versionToUse) {
        Update-ModuleManifest `
            -Path $moduleManifestFilePath `
            -ModuleVersion $versionToUse
    }
}
