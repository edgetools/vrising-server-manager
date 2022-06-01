$private:function_libraries = @(
    "$PSScriptRoot\Private",
    "$PSScriptRoot\Public"
)

foreach ($function_library in $private:function_libraries) {
    Write-Debug "Checking for function library: $function_library"
    if (-Not (Test-Path -Path $function_library -PathType Container)) {
        Write-Debug "Function library not found, skipping: $function_library"
        continue
    }
    Write-Debug "Checking for files inside function library: $function_library"
    $function_library_script_files = @()
    $function_library_script_files = Get-ChildItem -Path $function_library -Filter '*.ps1' -File -Recurse
    foreach ($function_library_script_file in $function_library_script_files) {
        $function_library_script_file_path = $function_library_script_file.FullName
        Write-Debug "Loading function library file: $function_library_script_file_path"
        . $function_library_script_file_path
        Write-Debug "Loaded function library file: $function_library_script_file_path"
    }
}

asdfasdf
