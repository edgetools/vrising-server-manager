class VRisingServerSettingsFile {
    # hidden [string] $_filePath
    # hidden [pscustomobject] $_contents

    # hidden [void] Load() {
    # }

    # GetKeys -- move this to VRisingServer later, fuck it
    # 
    hidden static [string[]] GetKeys() {
        # first, load the default file path for the type (host/game/voip, voip won't have default)
        # check if the key provided has any periods (foo.bar)
        # if it does, split, and perform lookups on the items first, e.g.:
        # foo.bar.ba
        # lookup $content.foo.bar.ba*
        # if no periods, perform a lookup against all keys in the first level
        # (basically, periods will change the scope of the 'get keys from psobject properties')
        return $null
    }

    hidden static [scriptblock] GenerateGetScriptBlock([string]$name, [string]$filePath) {
        # TODO
        # can i just programmatically build up the search depth using a list? e.g.
        # $searchKey = @('Name')
        # $searchKey = @('Rcon', 'Enabled')
        # TODO 2.0 !!
        # 1) (not doing this, doing #2 instead) for this approach,
        #    pass the sourceObject contents down with it
        #    so that you're only reading the disk at the top of the recursion tree
        # 2) switch away from object model and use a cmdlet
        #    e.g. vrset foo host Rcon.Enabled False
        #         vrset [shortName] [settingsType] [settingName] [settingValue]
        $sb = @"
return [VRisingServerSettingsFile]::GetValue('$name', '$filePath')
"@
        return [scriptblock]::Create($sb)
    }

    hidden static [psobject] GetValue([string]$name, [string]$filePath) {
        # todo
        # process values before returning
        $sourceObject = [VRisingServerSettingsFile]::Load()
        return $sourceObject.$name
    }

    hidden static [void] ConvertMembers([pscustomobject]$sourceObject, [pscustomobject]$destObject, [string]$filePath) {
        foreach ($property in $sourceObject.PSObject.Properties) {
            Write-Host "processing $($property.Name) => $($property.TypeNameOfValue)"
            switch ($property.TypeNameOfValue) {
                # 'System.Management.Automation.PSCustomObject' {
                #     $subDestObject = [pscustomobject]@{}
                #     [VRisingServerSettingsFile]::ConvertMembers($destObject, $subDestObject, $filePath)
                # }
                Default {
                    $destObject | Add-Member `
                        -Name $property.Name `
                        -MemberType ScriptProperty `
                        -Value ([VRisingServerSettingsFile]::GenerateGetScriptBlock($property.Name, $filePath))
                }
            }
        }
    }

    static [pscustomobject] Load([string]$filePath) {
        $sourceObject = Get-Content -Raw -LiteralPath $filePath | ConvertFrom-Json
        $destObject = [pscustomobject]@{}
        [VRisingServerSettingsFile]::ConvertMembers($sourceObject, $destObject, $filePath)
        return $destObject
    }
}
