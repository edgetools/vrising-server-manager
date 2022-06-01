# this should be able to use an in-memory version of the servers
# add a parameter with a default value that specifies the source
# this way when running in unit tests you can override it

# this function should return an object with all the server details
# under the hood it will call Read-VRisingServerConfigFile if it isn't passed existing data for it

function Get-VRisingServer {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [hashtable]
        $VRisingServerData = $null
    )

}
