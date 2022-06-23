function ServerSettingsFileArgumentCompleter {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )

    if ($FakeBoundParameters.ShortName.Count -gt 1) {
        $shortName = $FakeBoundParameters.ShortName[0]
    } else {
        $shortName = $FakeBoundParameters.ShortName
    }

    switch ($ParameterName) {
        'SettingName' {
            # Foo ->
            #   <- FooBar
            #   <- FooBaz
            # Foo. ->
            #   <- Foo.Foo
            #   <- Foo.Bar
            # Foo.F ->
            #   <- Foo.Foo
            # Foo.F.Foo ->
            #   <- (null) -- don't fuzzy search on middle
            if ($false -eq $FakeBoundParameters.ContainsKey('ShortName')) {
                return
            }
            $server = Get-VRisingServer -ShortName $shortName
            if ($null -eq $server) {
                return
            }
            if ($false -eq $FakeBoundParameters.ContainsKey('SettingsType')) {
                return
            }
            $serverSettingsKeys = $server.FindSettingsTypeKeys($FakeBoundParameters.SettingsType, "*$WordToComplete*")
            foreach ($settingsKey in $serverSettingsKeys) {
                [System.Management.Automation.CompletionResult]::New($settingsKey)
            }
            return
        }
        'SettingValue' {
            if ($false -eq $FakeBoundParameters.ContainsKey('SettingsType')) {
                return
            }
            if ($false -eq $FakeBoundParameters.ContainsKey('SettingName')) {
                return
            }
            $suggestedValues = [VRisingServer]::GetSuggestedSettingsValues(
                $FakeBoundParameters.SettingsType,
                $shortName,
                $FakeBoundParameters.SettingName,
                $WordToComplete)
            foreach ($suggestedValue in $suggestedValues) {
                if ($suggestedValue -is [System.String]) {
                    [System.Management.Automation.CompletionResult]::New("`"$suggestedValue`"")
                } else {
                    [System.Management.Automation.CompletionResult]::New($suggestedValue)
                }
            }
            return
        }
        Default {
            return
        }
    }
}
