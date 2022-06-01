# list of function libraries
$private:function_libraries = @(
    "$PSScriptRoot\Private",
    "$PSScriptRoot\Public"
)

# load all script files from the function libraries
foreach ($private:function_library in $private:function_libraries) {
    Write-Debug "Checking for function library: $private:function_library"
    if (-Not (Test-Path -Path $private:function_library -PathType Container)) {
        Write-Debug "Function library not found, skipping: $private:function_library"
        continue
    }
    Write-Debug "Checking for files inside function library: $private:function_library"
    $private:function_library_script_files = @()
    $private:function_library_script_files = Get-ChildItem -Path $private:function_library -Filter '*.ps1' -File -Recurse
    foreach ($private:function_library_script_file in $private:function_library_script_files) {
        $private:function_library_script_file_path = $private:function_library_script_file.FullName
        Write-Debug "Loading function library file: $private:function_library_script_file_path"
        . $private:function_library_script_file_path
        Write-Debug "Loaded function library file: $private:function_library_script_file_path"
    }
}
