class VRisingServerProperties {
    hidden [string] $_filePath
    hidden [System.Threading.Mutex] $_propertiesFileMutex

    VRisingServerProperties([string]$filePath) {
        $this._filePath = $filePath
        $fileName = ($filePath -split '\\')[-1]
        $this._propertiesFileMutex = [System.Threading.Mutex]::New($false, "VRisingServerProperties-$fileName")
    }

    [string] GetFilePath() {
        return $this._filePath
    }

    hidden [psobject] ReadProperty([string]$name) {
        return $this.ReadProperties(@($name)).$name
    }

    hidden [psobject] ReadProperties([string[]]$names) {
        if ($false -eq (Test-Path -LiteralPath $this._filePath -PathType Leaf)) {
            return $null
        }
        $fileContent = Get-Content -Raw -LiteralPath $this._filePath | ConvertFrom-Json
        $properties = [hashtable]@{}
        foreach ($name in $names) {
            if ($fileContent.PSObject.Properties.Name -contains $name) {
                $properties[$name] = $fileContent.$name
            }
        }
        return [pscustomobject]$properties
    }

    hidden [void] WriteProperty([string]$name, [psobject]$value) {
        $this.WriteProperties(@{$name=$value})
    }

    hidden [void] WriteProperties([hashtable]$nameValues) {
        # get dir for path
        $serverFileDir = $this._filePath | Split-Path -Parent
        # check if server dir exists
        if ($false -eq (Test-Path -LiteralPath $serverFileDir -PathType Container)) {
            # create it
            New-Item -Path $serverFileDir -ItemType Directory | Out-Null
        }
        try {
            $this._propertiesFileMutex.WaitOne()
            # check if file exists
            if ($true -eq (Test-Path -LiteralPath $this._filePath -PathType Leaf)) {
                $fileContent = Get-Content -Raw -LiteralPath $this._filePath | ConvertFrom-Json
            } else {
                $fileContent = [PSCustomObject]@{}
            }
            foreach ($nameValue in $nameValues.GetEnumerator()) {
                if ($fileContent.PSObject.Properties.Name -contains $nameValue.Name) {
                    $fileContent.$($nameValue.Name) = $nameValue.Value
                } else {
                    $fileContent | Add-Member -MemberType NoteProperty -Name $nameValue.Name -Value $nameValue.Value
                }
            }
            $fileContent | ConvertTo-Json | Out-File -LiteralPath $this._filePath
        } finally {
            $this._propertiesFileMutex.ReleaseMutex()
        }
    }
}
