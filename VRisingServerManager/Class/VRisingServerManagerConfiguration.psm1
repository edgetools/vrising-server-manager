class VRisingServerManagerConfiguration {
    [string] $FilePath
    [string] $SteamCmdFilePath
    [string] $DefaultServerBaseDir
    [string] $DefaultSaveDir
    [string] $DefaultInstallDir

    VRisingServerManagerConfiguration([string]$filePath) {
        $this.FilePath = $filePath
    }

    [VRisingServerManagerConfiguration] Load() {
        return $null
    }

    [void] Save([VRisingServerManagerConfiguration]$serverManagerConfig) {}
}
