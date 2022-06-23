class VRisingServerException : Exception {
    VRisingServerException()
            : base("an error occurred") {}

    VRisingServerException([string]$message)
            : base($message) {}

    VRisingServerException([string]$message, [Exception]$innerException)
            : base($message, $innerException) {}
}
