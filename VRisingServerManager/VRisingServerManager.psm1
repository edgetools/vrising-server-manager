using module .\Class\VRisingServer.psm1

# module parameters
$ErrorActionPreference = 'Stop'

# list of function libraries
$private:functionLibraries = @(
    "$PSScriptRoot\Private",
    "$PSScriptRoot\Public"
)

# load all script files from the function libraries
foreach ($private:functionLibrary in $private:functionLibraries) {
    Write-Debug "Checking for function library: $private:functionLibrary"
    if (-Not (Test-Path -Path $private:functionLibrary -PathType Container)) {
        Write-Debug "Function library not found, skipping: $private:functionLibrary"
        continue
    }
    Write-Debug "Checking for files inside function library: $private:functionLibrary"
    $private:functionLibraryScriptFiles = @()
    $private:functionLibraryScriptFiles = Get-ChildItem -Path $private:functionLibrary -Filter '*.ps1' -File -Recurse
    foreach ($private:functionLibraryScriptFile in $private:functionLibraryScriptFiles) {
        $private:functionLibraryScriptFilePath = $private:functionLibraryScriptFile.FullName
        Write-Debug "Loading function library file: $private:functionLibraryScriptFilePath"
        . $private:functionLibraryScriptFilePath
        Write-Debug "Loaded function library file: $private:functionLibraryScriptFilePath"
    }
}

ExportAliases
