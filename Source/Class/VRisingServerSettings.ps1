class VRisingServerSettings {
    static hidden [string] $SETTINGS_DIR_NAME = 'Settings'

    hidden [System.Threading.Mutex] $_settingsFileMutex
    hidden [VRisingServerProperties] $_properties

    VRisingServerSettings([VRisingServerProperties] $properties) {
        $this._properties = $properties
        $this._settingsFileMutex = [System.Threading.Mutex]::New($false, "VRisingServerSettings-$($properties.ReadProperty('ShortName'))")
    }

    [psobject] GetHostSetting([string]$settingName) {
        return $this.GetSettingsTypeValue([VRisingServerSettingsType]::Host, $settingName)
    }

    [psobject] GetGameSetting([string]$settingName) {
        return $this.GetSettingsTypeValue([VRisingServerSettingsType]::Game, $settingName)
    }

    [psobject] GetVoipSetting([string]$settingName) {
        return $this.GetSettingsTypeValue([VRisingServerSettingsType]::Voip, $settingName)
    }

    [void] SetHostSetting([string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        $this.SetSettingsTypeValue([VRisingServerSettingsType]::Host, $settingName, $settingValue, $resetToDefault)
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Host Setting '$settingName' modified")
    }

    [void] SetGameSetting([string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        $this.SetSettingsTypeValue([VRisingServerSettingsType]::Game, $settingName, $settingValue, $resetToDefault)
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Game Setting '$settingName' modified")
    }

    [void] SetVoipSetting([string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        $this.SetSettingsTypeValue([VRisingServerSettingsType]::Voip, $settingName, $settingValue, $resetToDefault)
        [VRisingServerLog]::Info("[$($this._properties.ReadProperty('ShortName'))] Voip Setting '$settingName' modified")
    }

    hidden [void] SetSettingsTypeValue([VRisingServerSettingsType]$settingsType, [string]$settingName, [psobject]$settingValue, [bool]$resetToDefault) {
        if ($true -eq [string]::IsNullOrWhiteSpace($settingName)) {
            throw [VRisingServerException]::New("settingName cannot be null or empty", [System.ArgumentNullException]::New('settingName'))
        }
        try {
            $this._settingsFileMutex.WaitOne()
            # skip getting default value if it's being reset
            $defaultValue = $null
            if ($false -eq $resetToDefault) {
                $defaultSettings = $null
                switch ($settingsType) {
                    ([VRisingServerSettingsType]::Host) {
                        $defaultSettings = $this.GetDefaultHostSettingsFile()
                        break
                    }
                    ([VRisingServerSettingsType]::Game) {
                        $defaultSettings = $this.GetDefaultGameSettingsFile()
                        break
                    }
                    ([VRisingServerSettingsType]::Voip) {
                        $defaultSettings = $this.GetDefaultVoipSettingsFile()
                        break
                    }
                }
                # get default value
                $defaultValue = $this.GetSetting($defaultSettings, $settingName)
                # if default value matches suggested value, reset = true
                if ($true -eq $this.ObjectsAreEqual($defaultValue, $settingValue)) {
                    $resetToDefault = $true
                }
            }

            # read the file
            $explicitSettings = $null
            $settingsFilePath = $null
            switch ($settingsType) {
                ([VRisingServerSettingsType]::Host) {
                    $explicitSettings = $this.GetHostSettingsFile()
                    $settingsFilePath = $this.GetHostSettingsFilePath()
                    break
                }
                ([VRisingServerSettingsType]::Game) {
                    $explicitSettings = $this.GetGameSettingsFile()
                    $settingsFilePath = $this.GetGameSettingsFilePath()
                    break
                }
                ([VRisingServerSettingsType]::Voip) {
                    $explicitSettings = $this.GetVoipSettingsFile()
                    $settingsFilePath = $this.GetVoipSettingsFilePath()
                    break
                }
            }

            # reset or modify the value
            if ($true -eq $resetToDefault) {
                $this.DeleteSetting($explicitSettings, $settingName)
            } else {
                $explicitSettings = $this.SetSetting($explicitSettings, $settingName, $settingValue)
            }

            # write the file
            $explicitSettings | ConvertTo-Json | Out-File -LiteralPath $settingsFilePath
        } finally {
            # unlock mutex
            $this._settingsFileMutex.ReleaseMutex()
        }
    }

    hidden [psobject] GetSettingsTypeValue([VRisingServerSettingsType]$settingsType, [string]$settingName) {
        $defaultSettings = $null
        $explicitSettings = $null
        switch ($settingsType) {
            ([VRisingServerSettingsType]::Host) {
                $defaultSettings = $this.GetDefaultHostSettingsFile()
                $explicitSettings = $this.GetHostSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Game) {
                $defaultSettings = $this.GetDefaultGameSettingsFile()
                $explicitSettings = $this.GetGameSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Voip) {
                $defaultSettings = $this.GetDefaultVoipSettingsFile()
                $explicitSettings = $this.GetVoipSettingsFile()
                break
            }
        }
        $this.MergePSObjects($defaultSettings, $explicitSettings)
        if ([string]::IsNullOrWhiteSpace($settingName)) {
            return $defaultSettings
        } elseif ($settingName.Contains('*')) {
            $matchedSettings = $this.GetSettingsKeys($defaultSettings, $null) -like $settingName
            $filteredSettings = $this.FilterSettings($defaultSettings, $matchedSettings)
            return $filteredSettings
        } else {
            return $this.GetSetting($defaultSettings, $settingName)
        }
    }

    hidden [string[]] FindSettingsTypeKeys([VRisingServerSettingsType]$settingsType, [string]$searchKey) {
        $settings = $null
        switch ($settingsType) {
            ([VRisingServerSettingsType]::Host) {
                $settings = $this.GetDefaultHostSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Game) {
                $settings = $this.GetDefaultGameSettingsFile()
                break
            }
            ([VRisingServerSettingsType]::Voip) {
                $settings = $this.GetDefaultVoipSettingsFile()
                break
            }
        }
        return $this.GetSettingsKeys($settings, $null) -like $searchKey
    }

    hidden [string[]] GetSettingsKeys($settings, [string]$prefix) {
        $keys = [System.Collections.ArrayList]::new()
        foreach ($property in $settings.PSObject.Properties) {
            if ($property.TypeNameOfValue -eq 'System.Management.Automation.PSCustomObject') {
                $keys.AddRange($this.GetSettingsKeys($property.Value, "$($property.Name)."))
            } else {
                $keys.Add($property.Name)
            }
        }
        for ($i = 0; $i -lt $keys.Count; $i++) {
            $keys[$i] = $prefix + $keys[$i]
        }
        return $keys.ToArray([string])
    }

    # take a source object and merge an overlay on top of it
    # does not clone, modifies any objects passed by reference
    hidden [void] MergePSObjects([psobject]$sourceObject, [psobject]$overlay) {
        if ($null -eq $overlay) {
            return
        }
        if ($null -eq $sourceObject) {
            $sourceObject = $overlay
        }
        # iterate through the properties on the overlay
        $overlay.PSObject.Properties | ForEach-Object {
            $currentProperty = $_
            # if the sourceobject does NOT contain that property, just assign it from the overlay
            if ($sourceObject.PSObject.Properties.Name -notcontains $currentProperty.Name) {
                $sourceObject | Add-Member `
                    -MemberType NoteProperty `
                    -Name $currentProperty.Name `
                    -Value $currentProperty.Value
            }
            # if the sourceobject DOES contain that property, check first if it's a container (psobject)
            switch ($currentProperty.TypeNameOfValue) {
                'System.Management.Automation.PSCustomObject' {
                    # if it's a container, call this function on those subobjects (recursive)
                    $this.MergePSObjects($sourceObject.PSObject.Properties[$currentProperty.Name].Value, $currentProperty.Value)
                    break
                }
                Default {
                    # if it's NOT a container, just overlay the value directly on top of it
                    $sourceObject | Add-Member `
                        -MemberType NoteProperty `
                        -Name $currentProperty.Name `
                        -Value $currentProperty.Value `
                        -Force
                    break
                }
            }
        }
    }

    hidden [bool] ObjectsAreEqual([psobject]$a, [psobject]$b) {
        # simple dumbed down recursive comparison function
        # specifically for comparing values inside the [pscustomobject] from a loaded settings file
        # does not handle complex types
        $a_type = $a.GetType().Name
        $b_type = $b.GetType().Name
        if ($a_type -ne $b_type) {
            return $false
        }
        switch ($a_type) {
            'PSCustomObject' {
                foreach ($property in $a.PSObject.Properties.GetEnumerator()) {
                    if ($b.PSObject.Properties.Name -notcontains $property.Name) {
                        return $false
                    }
                    $a_value = $property.Value
                    $b_value = $b.PSObject.Properties[$property.Name].Value
                    $expectedComparables = @(
                        'System.Boolean',
                        'System.Int32',
                        'System.Decimal',
                        'System.String')
                    switch ($property.TypeNameOfValue) {
                        'System.Object' {
                            if ($false -eq $this.ObjectsAreEqual($a_value, $b_value)) {
                                return $false
                            }
                            continue
                        }
                        { $_ -in $expectedComparables } {
                            if ($a_value -cne $b_value) {
                                return $false
                            }
                            continue
                        }
                        Default {
                            throw [VRisingServerException]::New("ObjectsAreEqual unexpected type: $_")
                        }
                    }
                }
            }
            Default {
                return $a -eq $b
            }
        }
        return $true
    }

    hidden [psobject] FilterSettings([psobject]$settings, [string[]]$settingNameFilter) {
        if (($null -eq $settings) -or
                ([string]::IsNullOrWhiteSpace($settingNameFilter))) {
            return $null
        }
        $filteredSettings = $null
        foreach ($settingName in $settingNameFilter) {
            $settingValue = $this.GetSetting($settings, $settingName)
            $filteredSettings = $this.SetSetting($filteredSettings, $settingName, $settingValue)
        }
        return $filteredSettings
    }

    hidden [psobject] GetSetting([psobject]$settings, [string]$settingName) {
        if ($null -eq $settings) {
            return $null
        }
        $settingNameSegments = $settingName -split '\.'
        $settingContainer = $settings
        # loop into the object
        # based on the number of segments to the path
        for ($i = 0; $i -lt $settingNameSegments.Count; $i++) {
            if ($i -eq ($settingNameSegments.Count - 1)) {
                # last item
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    return $null
                }
            } else {
                if ($null -eq $settingContainer) {
                    # parent pointed to a null value
                    return $null
                }
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    # missing sub key (given foo.bar, foo does not exist)
                    return $null
                }
                $settingContainer = $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value
            }
        }
        return $settingContainer.PSObject.Properties[$settingNameSegments[-1]].Value
    }

    hidden [void] DeleteSetting([psobject]$settings, [string]$settingName) {
        if ($null -eq $settings) {
            return
        }
        $settingNameSegments = $settingName -split '\.'
        $settingContainer = $settings
        # loop into the object
        # based on the number of segments to the path
        for ($i = 0; $i -lt $settingNameSegments.Count; $i++) {
            if ($i -eq ($settingNameSegments.Count - 1)) {
                # last item
                if ($settingContainer.PSObject.Properties.Name -contains $settingNameSegments[$i]) {
                    $settingContainer.PSObject.Properties.Remove($settingNameSegments[$i])
                }
            } else {
                if ($null -eq $settingContainer) {
                    # parent pointed to a null value
                    return
                }
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    # missing sub key (given foo.bar, foo does not exist)
                    return
                }
                $settingContainer = $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value
            }
        }
        return
    }

    # returns the modified (or new) settings object
    hidden [psobject] SetSetting([psobject]$settings, [string]$settingName, [psobject]$settingValue) {
        if ($null -eq $settings) {
            $settings = [PSCustomObject]@{}
        }
        $settingNameSegments = $settingName -split '\.'
        $settingContainer = $settings
        # loop into the object
        # based on the number of segments to the path
        for ($i = 0; $i -lt $settingNameSegments.Count; $i++) {
            if ($i -eq ($settingNameSegments.Count - 1)) {
                # last item
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    $settingContainer | Add-Member `
                        -MemberType NoteProperty `
                        -Name $settingNameSegments[$i] `
                        -Value $settingValue
                } else {
                    $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value = $settingValue
                }
            } else {
                if ($settingContainer.PSObject.Properties.Name -notcontains $settingNameSegments[$i]) {
                    # missing sub key (given foo.bar, foo does not exist)
                    # add the missing key
                    $settingContainer | Add-Member `
                        -MemberType NoteProperty `
                        -Name $settingNameSegments[$i] `
                        -Value ([PSCustomObject]@{})
                }
                $settingContainer = $settingContainer.PSObject.Properties[$settingNameSegments[$i]].Value
            }
        }
        return $settings
    }

    hidden [PSCustomObject] ReadSettingsFile([string]$filePath) {
        if ($true -eq (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            return Get-Content $filePath | ConvertFrom-Json
        }
        return $null
    }

    hidden [PSCustomObject] GetHostSettingsFile() {
        return $this.ReadSettingsFile($this.GetHostSettingsFilePath())
    }

    hidden [PSCustomObject] GetGameSettingsFile() {
        return $this.ReadSettingsFile($this.GetGameSettingsFilePath())
    }

    hidden [PSCustomObject] GetVoipSettingsFile() {
        return $this.ReadSettingsFile($this.GetVoipSettingsFilePath())
    }

    hidden [string] GetDefaultHostSettingsFilePath() {
        return Join-Path -Path $this.GetDefaultSettingsDirPath() -ChildPath 'ServerHostSettings.json'
    }

    hidden [string] GetDefaultGameSettingsFilePath() {
        return Join-Path -Path $this.GetDefaultSettingsDirPath() -ChildPath 'ServerGameSettings.json'
    }

    hidden [string] GetHostSettingsFilePath() {
        return Join-Path -Path $this.GetSettingsDirPath() -ChildPath 'ServerHostSettings.json'
    }

    hidden [string] GetGameSettingsFilePath() {
        return Join-Path -Path $this.GetSettingsDirPath() -ChildPath 'ServerGameSettings.json'
    }

    hidden [string] GetVoipSettingsFilePath() {
        return Join-Path -Path $this.GetSettingsDirPath() -ChildPath 'ServerVoipSettings.json'
    }

    hidden [PSCustomObject] GetDefaultHostSettingsFile() {
        return $this.ReadSettingsFile($this.GetDefaultHostSettingsFilePath())
    }

    hidden [PSCustomObject] GetDefaultGameSettingsFile() {
        return $this.ReadSettingsFile($this.GetDefaultGameSettingsFilePath())
    }

    hidden [string] GetDefaultSettingsDirPath() {
        return Join-Path -Path $this._properties.ReadProperty('InstallDir') -ChildPath 'VRisingServer_Data' |
            Join-Path -ChildPath 'StreamingAssets' |
            Join-Path -ChildPath 'Settings'
    }

    hidden [string] GetSettingsDirPath() {
        return Join-Path -Path $this._properties.ReadProperty('DataDir') -ChildPath ([VRisingServerSettings]::SETTINGS_DIR_NAME)
    }

    hidden [PSCustomObject] GetDefaultVoipSettingsFile() {
        return [PSCustomObject]@{
            VOIPEnabled = $false
            VOIPIssuer = $null
            VOIPSecret = $null
            VOIPAppUserId = $null
            VOIPAppUserPwd = $null
            VOIPVivoxDomain = $null
            VOIPAPIEndpoint = $null
            VOIPConversationalDistance = $null
            VOIPAudibleDistance = $null
            VOIPFadeIntensity = $null
        }
    }
}
