function ServerSettingsFileArgumentCompleter {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )

    function GetAutoCompletionServer() {
        if ($true -eq $FakeBoundParameters.ContainsKey('Server')) {
            # use -Server, if provided
            return $FakeBoundParameters.Server
        } elseif ($true -eq $FakeBoundParameters.ContainsKey('ShortName')) {
            # use -ShortName to get server
            if ($FakeBoundParameters.ShortName.Count -gt 1) {
                $shortName = $FakeBoundParameters.ShortName[0]
            } else {
                $shortName = $FakeBoundParameters.ShortName
            }
            return [VRisingServer]::GetServer($shortName)
        }
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
            $server = GetAutoCompletionServer
            if ($null -eq $server) {
                return
            }
            if ($false -eq $FakeBoundParameters.ContainsKey('SettingsType')) {
                return
            }
            $serverSettingsKeys = $server._settings.FindSettingsTypeKeys($FakeBoundParameters.SettingsType, "*$WordToComplete*")
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
            # take type
            # lookup name in type map
            # if value type (from map) is a collection type (has multiple known values):
            # - return collection matching input, sorted preferring input
            # - e.g. Host ListOnMasterServer '' -> True / False
            #        Host ListOnMasterServer 'Fa' -> False / True
            # if value type is not a collection type (has multiple known values):
            # - reach into settings
            # - extract the current or default value
            # - e.g. Host AutoSaveCount '' -> 50
            $suggestedValues = $null
            $mapResults = [VRisingServerSettingsMap]::Get(
                $FakeBoundParameters.SettingsType,
                $FakeBoundParameters.SettingName)
            if (($null -ne $mapResults) -and ($mapResults.Count -gt 0)) {
                # sort array results by those like result
                $sortedMapResults = [System.Collections.ArrayList]::New()
                foreach ($mapResult in $mapResults) {
                    if ($mapResult -like "$WordToComplete*") {
                        $sortedMapResults.Insert(0, $mapResult)
                    } else {
                        [void] $sortedMapResults.Add($mapResult)
                    }
                }
                $suggestedValues = $sortedMapResults.ToArray()
            } else {
                # value does not have known values, try to grab current value from server instead
                $server = GetAutoCompletionServer
                if ($null -ne $server) {
                    $suggestedValues = $server._settings.GetSettingsTypeValue(
                        $FakeBoundParameters.SettingsType,
                        $FakeBoundParameters.SettingName)
                }
            }
            foreach ($suggestedValue in $suggestedValues) {
                if ($suggestedValue -is [System.String]) {
                    [System.Management.Automation.CompletionResult]::New("`"$suggestedValue`"")
                } elseif ($suggestedValue -is [System.Boolean]) {
                    [System.Management.Automation.CompletionResult]::New("`$$suggestedValue")
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
