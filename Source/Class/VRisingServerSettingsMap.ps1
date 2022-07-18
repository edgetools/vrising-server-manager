class VRisingServerSettingsMap {
    static [hashtable] $_map

    static VRisingServerSettingsMap() {
        [VRisingServerSettingsMap]::_map = @{
            Host = @{
                AdminOnlyDebugEvents = [bool]
                DayOfReset = @('Any', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
                DisableDebugEvents = [bool]
                GameSettingsPreset = @(
                    'DuoPvP',
                    'HardcoreDuoPvP',
                    'HardcorePvP',
                    'Level30PvE',
                    'Level30PvP',
                    'Level50PvE',
                    'Level50PvP',
                    'Level70PvE',
                    'Level70PvP',
                    'SoloPvP',
                    'StandardPvE',
                    'StandardPvE_Easy',
                    'StandardPvE_Hard',
                    'StandardPvP',
                    'StandardPvP_Easy',
                    'StandardPvP_Hard',
                    ''
                )
                LanMode = [bool]
                ListOnMasterServer = [bool]
                Rcon = @{
                    Enabled = [bool]
                }
                Secure = [bool]
            }
            Game = @{
                GameModeType = @('PvP', 'PvE')
                CastleDamageMode = @('Always', 'Never', 'TimeRestricted')
                SiegeWeaponHealth = @('VeryLow', 'Low', 'Normal', 'High', 'VeryHigh')
                PlayerDamageMode = @('Always', 'TimeRestricted')
                CastleHeartDamageMode = @('CanBeDestroyedOnlyWhenDecaying', 'CanBeDestroyedByPlayers', 'CanBeSeizedOrDestroyedByPlayers')
                PvPProtectionMode = @('Disabled', 'VeryShort', 'Short', 'Medium', 'Long')
                DeathContainerPermission = @('Anyone', 'ClanMembers', 'OnlySelf')
                RelicSpawnType = @('Unique', 'Plentiful')
                CanLootEnemyContainers = [bool]
                BloodBoundEquipment = [bool]
                TeleportBoundItems = [bool]
                AllowGlobalChat = [bool]
                AllWaypointsUnlocked = [bool]
                FreeCastleClaim = [bool]
                FreeCastleDestroy = [bool]
                InactivityKillEnabled = [bool]
                DisableDisconnectedDeadEnabled = [bool]
                AnnounceSiegeWeaponSpawn = [bool]
                ShowSiegeWeaponMapIcon = [bool]
                # "VBloodUnitSettings": [] # TODO UNKNOWN CONTENTS
                # "UnlockedAchievements": [] # TODO UNKNOWN CONTENTS
                # "UnlockedResearchs": [] # TODO UNKNOWN CONTENTS
                PlayerInteractionSettings = @{
                    TimeZone = @('Local', 'UTC', 'PST', 'CET', 'CST')
                }
            }
            Voip = @{
                VOIPEnabled = [bool]
            }
            Service = @{
                UpdateOnStartup = [bool]
            }
        }
    }

    static [psobject[]] Get([string]$settingsType, [string]$settingName) {
        # split on dots
        $splitSettingName = $settingName -split '\.'
        $settingLeafName = $splitSettingName[-1]
        $mappedSettings = $null
        if ([string]::IsNullOrEmpty($splitSettingName)) {
            return $null
        } elseif ($splitSettingName.Count -eq 1) {
            $mappedSettings = [VRisingServerSettingsMap]::_map[$settingsType]
        } elseif ($splitSettingName.Count -gt 1) {
            # loop into the settings object
            # based on the number of segments to the search key
            $subSettings = [VRisingServerSettingsMap]::_map[$settingsType]
            for ($i = 0; $i -lt $splitSettingName.Count; $i++) {
                if ($i -eq ($splitSettingName.Count - 1)) {
                    # last item
                } else {
                    if ($false -eq $subSettings.ContainsKey($splitSettingName[$i])) {
                        # invalid sub key (given foo.bar, foo does not exist)
                        return $null
                    }
                    $subSettings = $subSettings[$splitSettingName[$i]]
                }
            }
            $mappedSettings = $subSettings
        }
        if ($false -eq $mappedSettings.ContainsKey($settingLeafName)) {
            return $null
        } else {
            if ($mappedSettings[$settingLeafName] -is [System.Reflection.TypeInfo]) {
                switch ($mappedSettings[$settingLeafName].Name) {
                    'Boolean' {
                        return @($true,$false)
                    }
                    Default {
                        return $null
                    }
                }
            } elseif ($mappedSettings[$settingLeafName] -is [array]) {
                return $mappedSettings[$settingLeafName]
            }
        }
        return $null
    }
}
