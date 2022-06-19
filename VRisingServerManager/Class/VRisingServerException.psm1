class VRisingServerException : Exception {
    hidden [string] $_shortName

    hidden [string] GetShortName() {
        return $this._shortName
    }

    static VRisingServerException() {
        Update-TypeData `
            -TypeName "VRisingServerException" `
            -MemberName ShortName `
            -MemberType ScriptProperty `
            -Value { return $this.GetShortName() } `
            -Force
    }

    VRisingServerException([string]$shortName)
            : base("Server '$shortName' has produced an error.") {
        $this._shortName = $shortName
    }

    VRisingServerException([string]$shortName, [string]$message)
            : base($message) {
        $this._shortName = $shortName
    }

    VRisingServerException([string]$shortName, [string]$message, [Exception]$innerException)
            : base($message, $innerException) {
        $this._shortName = $shortName
    }
}
