# V Rising Server Manager

Windows PowerShell cmdlets for easily managing multiple dedicated V Rising servers on a Windows machine

[![module](https://img.shields.io/powershellgallery/dt/VRisingServerManager)](https://www.powershellgallery.com/packages/VRisingServerManager/) [![main](https://github.com/edgetools/vrising-server-manager/actions/workflows/release.yaml/badge.svg)](https://github.com/edgetools/vrising-server-manager/actions/workflows/release.yaml?query=branch%3Amain++) [![main-auto](https://github.com/edgetools/vrising-server-manager/actions/workflows/release-dry-run.yaml/badge.svg?event=push)](https://github.com/edgetools/vrising-server-manager/actions/workflows/release-dry-run.yaml?query=branch%3Amain++)

_Ready to install? Jump to [Installation](#installation)_

## Features

- Out-of-box support for PowerShell 5.1+ (which is already included in most modern Windows installations)

- Start, Stop, Update, and Restart multiple servers with a service-like command interface

- Automatically update server on startup

- Servers run in the background so you can close the PowerShell window

- Search for and customize Game, Host, and Voip settings

- Read and tail log files

## Feature Roadmap

These features will be added in future releases

- (Coming Soon!) Automatically download and install `steamcmd` and `mcrcu`

- (Coming Soon!) Send system messages to players in-game from the console

- Automatically send system messages on restart or shutdown

- Automatically restart servers on a schedule

- Rotate and archive log files

- Archive save files

# Release Notes

<!-- begin release notes -->
## [0.7.0](https://www.github.com/edgetools/vrising-server-manager/compare/0.6.0...0.7.0) (2022-07-19)

### Features

* show time since last successful update ([801d909](https://www.github.com/edgetools/vrising-server-manager/commit/801d909fcacff32cb47f1ca114843d05c6be4cf9))
* allow update to fail on startup ([385653a](https://www.github.com/edgetools/vrising-server-manager/commit/385653a9bf4172de6337d49cc3f94246ec3cdfa6))

### Bug Fixes

* **Monitor:** prevent command errors from crashing the monitor ([c3a1fd5](https://www.github.com/edgetools/vrising-server-manager/commit/c3a1fd54088425937e723dc2265c3bd26e4c82af))
<!-- end release notes -->

# Table of Contents

[Requirements](#requirements)

[Installation](#installation)

- [Install from PowerShellGallery](#install-from-powershellgallery)

- [Install from source](#install-from-source)

[Usage](#usage)

- [Import the module](#import-the-module)

- [Set the Default Servers Folder](#set-the-default-servers-folder)

- [Set the Default Apps Folder](#set-the-default-apps-folder)

- [Create or import a Server](#create-or-import-a-server)

- [Check Server status](#check-server-status)

- [Update Server](#update-server)

- [Start Server](#start-server)

- [Stop Server](#stop-server)

- [Restart Server](#restart-server)

- [View Server Logs](#view-server-logs)

- [Send a System Message](#send-a-system-message)

- [Remove Server](#remove-server)

- [Disable Server Monitor](#disable-server-monitor)

- [Enable Server Monitor](#enable-server-monitor)

- [Update Server Manager](#update-server-manager)

[Concepts](#concepts)

- [VRisingServerManagerFlags](#vrisingservermanagerflags)

- [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption)

  - [SkipNewVersionCheck](#skipnewversioncheck)

  - [DefaultServersDir](#defaultserversdir)

- [Server](#server)

  - [ShortName](#shortname)

  - [DisplayName](#displayname)

  - [InstallDir](#installdir)

  - [DataDir](#datadir)

  - [LogDir](#logdir)

  - [UpdateOnStartup](#updateonstartup)

  - [AnnounceShutdown](#announceshutdown)

  - [ShutdownDelay](#shutdowndelay)

- [Setting](#setting)

  - [Host Setting](#host-setting)

  - [Game Setting](#host-setting)

  - [Voip Setting](#host-setting)

  - [Service Setting](#host-setting)

[Command Reference](#command-reference)

- [Using ShortName or Server](#using-shortname-or-server)

- [New-VRisingServer](#new-vrisingserver)

- [Get-VRisingServer](#get-vrisingserver)

- [Set-VRisingServer](#set-vrisingserver)

- [Start-VRisingServer](#start-vrisingserver)

- [Stop-VRisingServer](#stop-vrisingserver)

- [Update-VRisingServer](#update-vrisingserver)

- [Read-VRisingServerLogs](#read-vrisingserverlogs)

- [Send-VRisingServerMessage](#send-vrisingservermessage)

- [Remove-VRisingServer](#remove-vrisingserver)

- [Get-VRisingServerManagerConfigOption](#get-vrisingservermanagerconfigoption)

- [Set-VRisingServerManagerConfigOption](#set-vrisingservermanagerconfigoption)

- [Disable-VRisingServerMonitor](#disable-vrisingservermonitor)

- [Enable-VRisingServerMonitor](#enable-vrisingservermonitor)

[Technical Details](#technical-details)

[Development](#development)

- [Build Requirements](#build-requirements)

- [Building from source](#building-from-source)

[License](#license)

# Requirements

Requires **PowerShell 5.1** or greater

**Tip:** Check your PowerShell version with `$PSVersionTable.PSVersion.ToString()`

Tested with:

- Windows Server 2019
- Windows 10
- Windows 11

**Note:** Other platforms may also work that meet the minimum requirements, but have not been tested.

# Installation

## Install from PowerShellGallery

```pwsh
Install-Module -Name VRisingServerManager
```

OR

## Install from source

Follow the instructions below for [Building from source](#Building-from-source)

Copy the module folder into a [supported module path](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module)

# Usage

**Tip:** This module never deletes a server installation, game settings, or save data when removing a [Server](#server) configuration. You may safely delete and re-create or re-import a [Server](#server) configuration at any time.

## Import the module

Before you can run commands, you first must import the module.

**Tip:** Some module behavior can be temporarily customized using [VRisingServerManagerFlags](#vrisingservermanagerflags) prior to import

```pwsh
Import-Module VRisingServerManager
```

## Set the Default Servers Folder

To make creating servers easier, [vrcreate](#new-vrisingserver) uses the [DefaultServersDir](#defaultserversdir) to suggest a path for the [InstallDir](#installdir), [DataDir](#datadir), and [LogDir](#logdir).

**Tip:** If you prefer to put the `InstallDir`, `LogDir`, or `DataDir` in different locations (like separate drives), you can customize specific values for each path during server creation.

```pwsh
vrmset DefaultServersDir 'D:\VRisingServerManager\Servers'
```

## Set the Default Apps Folder

To make managing servers easier, if you don't have [steamcmd](#steamcmd) or [mcrcu](#mcrcu) yet, the module will automatically prompt to download and install them to the [DefaultAppsDir](#defaultappsdir).

You can override this path using [vrmset](#set-vrisingservermanagerconfigoption):

```pwsh
vrmset DefaultAppsDir 'D:\VRisingServerManager\Apps'
```

If you already have [steamcmd](#steamcmd) or [mcrcu](#mcrcu) installed, you can use them by setting their paths with [vrmset](#set-vrisingservermanagerconfigoption):

```pwsh
vrmset SteamCmdPath 'D:\VRisingServerManager\Apps\steamcmd\steamcmd.exe'
```

```pwsh
vrmset MCRCUPath 'D:\VRisingServerManager\Apps\mcrcu\mcrcu.exe'
```

## Create or import a Server

**Note:** This name must be a valid [ShortName](#shortname), and you can also change the [InstallDir](#installdir), [DataDir](#datadir), and [LogDir](#logdir) after creation.

To prompt for all required values:

```pwsh
vrcreate
```

To temporarily override the [DefaultServersDir](#defaultserversdir):

```pwsh
vrcreate `
  -ShortName MyServer `
  -ServersDir 'C:\Servers'
```

To explicitely provide some (or all) values at creation:

```pwsh
vrcreate `
  -ShortName MyServer `
  -DataDir 'C:\Servers\MyServer\Data' `
  -InstallDir 'C:\Servers\MyServer\Install' `
  -LogDir 'C:\Servers\MyServer\Log'
```

## Check Server status

List all Servers

```pwsh
vrget
```

List a specific Server

```pwsh
vrget MyServer
```

## Update Server

**Tip:** This can also be used for first-time installation

Update all Servers

```pwsh
vrupdate
```

Update a specific Server

```pwsh
vrupdate MyServer
```

## Start Server

Start all Servers

```pwsh
vrstart
```

Start a specific Server

```pwsh
vrstart MyServer
```

## Stop Server

Stop all Servers

```pwsh
vrstop
```

Stop a specific Server

```pwsh
vrstop MyServer
```

## Restart Server

Restart all Servers

```pwsh
vrrestart
```

Restart a specific Server

```pwsh
vrrestart MyServer
```

## View Server Logs

There are multiple log types which can be easily read using [vrlog](#read-vrisingserverlog), please refer to the [command description](#read-vrisingserverlog) for a full list of log types.

The most common log type you will read is the log from the dedicated game server, known as the `Game` log.

The `vrlog` command defaults to the `Game` log, so to read the log for a specific server, you can simply type:

```pwsh
vrlog MyServer
```

You may occasionally need to read other logs, like the logs from the process monitor.

To read a specific log for a specific server, in this example the `MonitorError` log:

```pwsh
vrlog MyServer MonitorError
```

To read the last `10` lines of a log and continuously watch the log for new changes, use `-Tail` and `-Follow` :

```pwsh
vrlog MyServer Game -Tail 10 -Follow
```

## Send a System Message

Message all Servers

```pwsh
vrsay 'This is a system message'
```

Message a specific Server

```pwsh
vrsay MyServer 'This is a system message'
```

## Remove Server

**Note:** to prevent unintentionally removing server data, this does not remove the [InstallDir](#installdir), [DataDir](#datadir), or [LogDir](#logdir) which must be manually deleted if you wish to completely uninstall a server installation.

If you accidentally remove a server, you can easily add it again with [vrcreate](#new-vrisingserver).

Remove all Servers

```pwsh
vrdelete
```

Remove a specific Server

```pwsh
vrdelete MyServer
```

## Disable Server Monitor

Disabling the server monitor process will cause it to shut down, but will still leave the server process running.

Disable all Server Monitors

```pwsh
vrdisable
```

Disable a specific Server Monitor

```pwsh
vrdisable MyServer
```

## Enable Server Monitor

**Note:** The server monitor automatically launches whenever running [Server](#server) commands.

Enable all Server Monitors

```pwsh
vrenable
```

Enable a specific Server Monitor

```pwsh
vrenable MyServer
```

## Update Server Manager

Steps to Update to a new version:

1. Stop (Disable) any running Monitor(s)
   ```pwsh
   vrdisable

   (VRisingServer) [foo] Monitor disabled
   ```
1. Wait for Monitor(s) to Stop, then verify Monitor(s) are "Disabled"
   ```pwsh
   vrget
   ```
   ```pwsh
   Monitor
   -------
   Disabled
   ```
1. Update the Module
   ```pwsh
   Update-Module -Name VRisingServerManager
   ```
1. Exit the current PowerShell session
   
   The module is compiled during import, so you **must** open a new powershell session after upgrading to ensure the new version is loaded correctly.

   ```pwsh
   exit
   ```
1. Open a new PowerShell session
1. Import the Updated Module
   ```pwsh
   Import-Module VRisingServerManager
   ```
1. Start (Re-Enable) the Monitor(s)
   ```pwsh
   vrenable

   (VRisingServer) [foo] Monitor enabled
   (VRisingServer) [foo] Monitor launched
   ```
1. Verify the Monitor(s) are Running (Idle)
   ```pwsh
   vrget
   ```
   ```pwsh
   Monitor
   -------
   Idle
   ```

# Concepts

## VRisingServerManagerFlags

Some module behavior can be temporarily customized by settings flags on `[hashtable] $VRisingServerManagerFlags` prior to import

Supported flags:

- `SkipNewVersionCheck`: Disables checking for new package versions when loading the module (see: [SkipNewVersionCheck](#skipnewversioncheck)).

Example:

```pwsh
$VRisingServerManagerFlags = @{
    SkipNewVersionCheck = $true
}
Import-Module VRisingServerManager
```

## VRisingServerManagerConfigOption

Some settings for the manager itself can be retrieved or modified using [vrmget](#get-vrisingservermanagerconfigoption) and [vrmset](#set-vrisingservermanagerconfigoption).

These settings are persisted to disk.

### SkipNewVersionCheck

Type: `boolean`

Default: `$false`

The module will automatically check [PowerShellGallery](https://www.powershellgallery.com/packages/VRisingServerManager) for new versions of the module.

This behavior can be disabled by setting **SkipNewVersionCheck** to `$true`

### DefaultServersDir

Type: `string`

Default: `D:\VRisingServerManager\Servers`

When new servers are created, their [InstallDir](#installdir), [DataDir](#datadir), and [LogDir](#logdir) are automatically configured as a subfolder of **DefaultServersDir** named after their [ShortName](#shortname) (e.g. `D:\VRisingServers\MyServer`)

Example: [Set the Default Servers Folder](#set-the-default-servers-folder)

### DefaultAppsDir

Type: `string`

Default: `D:\VRisingServerManager\Apps`

If [steamcmd](#steamcmd) or [mcrcu](#mcrcu) are automatically installed, they will be installed to a subfolder of the **DefaultAppsDir**

Example: [Set the Default Apps Folder](#set-the-default-apps-folder)

## Server

The **Server** represents a single server configuration in the manager. When using [vrget](#get-vrisingserver), a list of Servers is returned and can be interacted with using its methods and properties.

Server configuration files are stored in `C:\ProgramData\edgetools\VRisingServerManager\Servers`

### ShortName

Type: `string`

The **ShortName** is a concise nickname for an individual [Server](#server) which is used when running various manager commands.

Unlike the [DisplayName](#displayname), the only allowed characters are alphanumeric ( `A-Z` `a-z` `0-9` ), dash ( `-` ), and underscore ( `_` )

### DisplayName

Type: `string`

The **DisplayName** is what players will see when searching for the server online or connecting to it in game.

This is a [Host Setting](#host-setting) and can be modified using [vrset](#set-vrisingserver).

### InstallDir

Type: `string`

The **InstallDir** is where [steamcmd](#steamcmd) will install the V Rising dedicated game server files.

This is a [Service Setting](#service-setting) and can be modified using [vrset](#set-vrisingserver).

### DataDir

Type: `string`

The **DataDir** is where the dedicated game server will store its save files and settings.

This is a [Service Setting](#service-setting) and can be modified using [vrset](#set-vrisingserver).

### LogDir

Type: `string`

The **LogDir** is where log files from the dedicated game server, server updates, and the process monitor will be written.

These files can easily be read using [vrlog](#read-vrisingserverlog).

This is a [Service Setting](#service-setting) and can be modified using [vrset](#set-vrisingserver).

### UpdateOnStartup

Type: `boolean`

Default: `$true`

If **UpdateOnStartup** is enabled, [steamcmd](#steamcmd) will automatically run and install any updates prior to starting or restarting the dedicated game server.

This is a [Service Setting](#service-setting) and can be modified using [vrset](#set-vrisingserver).

### AnnounceShutdown

Type: `boolean`

Default: `$true`

If **AnnounceShutdown** is enabled, [mcrcu](#mcrcu) will automatically run and announce when the server is being shut down.

If [ShutdownDelay](#shutdowndelay) is greater than `0`, a message will also be sent every minute until shutdown.

This is a [Service Setting](#service-setting) and can be modified using [vrset](#set-vrisingserver).

### ShutdownDelay

Type: `int`

Default: `5`

**ShutdownDelay** is the duration in minutes to wait until shutting down the server when receiving a [stop](#stop-vrisingserver) or [restart](#restart-vrisingserver) command.

If the value is unset or set to `0`, the server shuts down immediately.

This is a [Service Setting](#service-setting) and can be modified using [vrset](#set-vrisingserver).

## Setting

Many settings for the dedicated game server can be retrieved using [vrget](#get-vrisingserver) and modified using [vrset](#set-vrisingserver).

### Host Setting

A **Host Setting** correlates to a value in `ServerHostSettings.json` inside the `Settings` folder of the [DataDir](#datadir).

### Game Setting

A **Game Setting** correlates to a value in `ServerGameSettings.json` inside the `Settings` folder of the [DataDir](#datadir).

### Voip Setting

A **Voip Setting** correlates to a value in `ServerVoipSettings.json` inside the `Settings` folder of the [DataDir](#datadir).

### Service Setting

A **[Service](#service) Setting** correlates to a configurable option when running the dedicated game server using this module.

## Monitor

The Process Monitors are separate PowerShell sessions which are automatically launched, one for each server, whenever a command is executed.

This allows orchestrating complex features like waiting for the [ShutdownDelay](#shutdowndelay) and running [UpdateOnStartup](#updateonstartup) against multiple servers in parallel, all without blocking the operator from using the console.

Once the monitor is launched, it checks for any commands in the queue, executes them if found, and when it has nothing else to do, then it exits.

Some commands support a `-Queue` option which allows the command to be queued for execution, which is useful for ensuring a task is still ran even if the monitor is currently busy.

Since it launches [steamcmd](#steamcmd) and the dedicated game server in separate processes, the monitor can exit and the server will keep running.

See [Technical Details](#technical-details) for more detailed information.

# Command Reference

**Note:** Most commands have convenient aliases, which are automatically configured when importing the module. Command examples will use the alias, when available.

## Using ShortName or Server

Most commands can operate against specific server(s), which may be specified as a [ShortName](#shortname) or using the [Server](#server) object.

### Using ShortName

When using the `-ShortName`, pass the name directly to the command:

```pwsh
vrfoo MyServer
```

### Using Server

When using `-Server`, first store the server in an object using [vrget](#get-vrisingserver):

```pwsh
$myserver = vrget MyServer
```

Then pass the object using `-Server`:

```pwsh
vrfoo -Server $myserver
```

## New-VRisingServer

Alias: **vrcreate**

```pwsh
vrcreate [ShortName] [OPTIONS]
```

Creates new [Server](#server) configuration on the local machine with the specified [ShortName](#shortname), [DataDir](#datadir), [InstallDir](#installdir), and [LogDir](#logdir).

### Arguments

- `ShortName`: **Required**. The [ShortName](#shortname) to use for the new server.

  **Tip:** This value will be used when running most commands, so pick something short, concise, and easy to type.

### Options

- `-ServersDir`: _Optional_. A directory path to use instead of the [DefaultServersDir](#defaultserversdir). This value is used when generating the suggested values for `DataDir`, `InstallDir`, and `LogDir`. Type: `string`. Example: `D:\VRisingServerManager\Servers`

- `-DataDir`: _Optional_. A directory path to use for the [DataDir](#installdir) instead of the suggested directory. Type: `string`. Example: `D:\VRisingServerManager\Servers\MyServer\Data`

- `-InstallDir`: _Optional_. A directory path to use for the [InstallDir](#installdir) instead of the suggested directory. Type: `string`. Example: `D:\VRisingServerManager\Servers\MyServer\Install`

- `-LogDir`: _Optional_. A directory path to use for the [LogDir](#logdir) instead of the suggested directory. Type: `string`. Example: `D:\VRisingServerManager\Servers\MyServer\Log`

### Examples

- [Create or import a Server](#create-or-import-a-server)

## Get-VRisingServer

Alias: **vrget**

### For retrieving a [Server](#server):

```pwsh
vrget [ShortNames or Servers]
```

#### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to retrieve.

#### Examples

- [Check Server status](#check-server-status)

### For retrieving a server [Setting](#setting):

```pwsh
vrget [ShortNames or Servers] [SettingsType] [SettingName]
```

#### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to retrieve specified setting from.

- `SettingsType`: **Required**. The [Setting](#setting) type to retrieve. Example: `Host`

- `SettingName`: _Optional_. The [Setting](#setting) name to retrieve.

  - If unspecified, all values for the specified setting type will be retrieved.

  - You can use wildcards (`*`) to search for any setting names matching input.
  
    Example: `vrget MyServer Game *Castle*`

## Set-VRisingServer

Alias: **vrset**

Modifies or resets the value of a [Setting](#setting) for specified [Server](#server)(s).

```pwsh
vrset [ShortNames or Servers] [SettingsType] [SettingName] [SettingValue or Default]
```

#### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to modify specified setting for.

- `SettingsType`: **Required**. The [Setting](#setting) type to modify. Example: `Host`

- `SettingName`: **Required**. The [Setting](#setting) name to modify. Example: `Port`

- `SettingValue` or `-Default`: **Required**. The value to assign to the specified [Setting](#setting).
  
  - If the specified value matches the default value, or if `-Default` is used instead, then any overridden value will be reset back to the default.
    
    Example: `vrset MyServer Host Port -Default`

## Start-VRisingServer

Alias: **vrstart**

```pwsh
vrstart [ShortNames or Servers] [OPTIONS]
```

Starts specified [Server](#server)(s), including orchestrating [UpdateOnStartup](#updateonstartup), if enabled.

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to start.

### Options

- `-Queue`: _Optional_. Adds the command to the [Monitor](#monitor) queue even if a command is already running. Type: `switch`

### Examples

- [Start Server](#start-server)

## Stop-VRisingServer

Alias: **vrstop**

```pwsh
vrstop [ShortNames or Servers] [OPTIONS]
```

Stops specified [Server](#server)(s), including orchestrating [AnnounceShutdown](#announceshutdown) and [ShutdownDelay](#shutdowndelay), if enabled.

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to stop.

### Options

- `-Queue`: _Optional_. Adds the command to the [Monitor](#monitor) queue even if a command is already running. Type: `switch`

### Examples

- [Stop Server](#stop-server)

## Restart-VRisingServer

Alias: **vrrestart**

```pwsh
vrrestart [ShortNames or Servers] [OPTIONS]
```

Restarts specified [Server](#server)(s), including orchestrating [AnnounceShutdown](#announceshutdown), [ShutdownDelay](#shutdowndelay), and [UpdateOnStartup](#updateonstartup), if enabled.

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to restart.

### Options

- `-Queue`: _Optional_. Adds the command to the [Monitor](#monitor) queue even if a command is already running. Type: `switch`

### Examples

- [Restart Server](#restart-server)

## Update-VRisingServer

Alias: **vrupdate**

```pwsh
vrupdate [ShortNames or Servers] [OPTIONS]
```

Updates specified [Server](#server)(s) using [steamcmd]().

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to update.

### Options

- `-Queue`: _Optional_. Adds the command to the [Monitor](#monitor) queue even if a command is already running. Type: `switch`

### Examples

- [Update Server](#update-server)

## Read-VRisingServerLogs

Alias: **vrlog**

```pwsh
vrlog [ShortName or Server] [LogType] [OPTIONS]
```

Reads a specified [Server](#server)'s log file from disk.

### Arguments

- [ShortName or Server](#using-shortname-or-server): **Required**. The `Server` to read a log file from.

- `LogType`: _Optional_. The Log type to read. Default: `Game`
  
  Log types:

  - `Game`
    
    The `Game` log contains the output from `VRisingServer.exe`.

  - `Update`

    The `Update` log contains the output from [steamcmd](#steamcmd) during the update process.

  - `UpdateError`

    The `UpdateError` log contains error output from [steamcmd](#steamcmd) during the update process. This log will typically be empty unless an error occured during an update.

  - `Monitor`

    The `Monitor` log contains the output from the process [Monitor](#monitor) which orchestrates commands such as starting, stopping, restarting, and updating the server.

  - `MonitorError`

    The `MonitorError` log contains error output from the process [Monitor](#monitor). This log will typically be empty unless the monitor crashed.

  - `Service`

    The `Service` log contains any standard output from `VRisingServer.exe`. This log will typically be empty because V Rising sends the log output to the `Game` log instead.

  - `ServiceError`

    The `Service` log contains error output from `VRisingServer.exe`. This log will typically be empty unless the dedicated server crashes while running, but may still be empty as errors from launching the server are generally printed to the `Game` log or the `MonitorError` log.

### Options

- `-Tail [LINES]`: _Optional_. Return the last `LINES` number from the log file. Default: Return all lines.

- `-Follow`: _Optional_. Continue to watch the log file for new output and print it as it arrives. **Press Ctrl+C to stop.**

### Examples

- [View Server Logs](#view-server-logs)

## Send-VRisingServerMessage

Alias: **vrsay**

```pwsh
vrsay [ShortNames or Servers] [Message]
```

Sends [Server](#server)(s) a system message using [mcrcon](#mcrcon).

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to update.

- `Message`: **Required**. The message to send. Type: `string`.

### Examples

- [Send a System Message](#send-a-system-message)

## Remove-VRisingServer

Alias: **vrdelete**

```pwsh
vrdelete [ShortNames or Servers] [OPTIONS]
```

Removes specified [Server](#server) configuration(s) from the local machine.

Does not remove the [InstallDir](#installdir), [DataDir](#datadir), or [LogDir](#logdir) which must be manually deleted if you wish to completely uninstall a server installation.

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to remove.

### Options

- `-Force`: _Optional_. Forces removal of config file even if the server is currently running or being orchestrated. **Use `-Force` at your own risk!** Type: `switch`. Default: Unset.

### Examples

- [Remove Server](#remove-server)

## Disable-VRisingServerMonitor

Alias: **vrdisable**

```pwsh
vrdisable [ShortNames or Servers]
```

Disables the server [Monitor](#monitor) for specified [Server](#server)(s).

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to disable the monitor for.

### Examples

- [Disable Server Monitor](#disable-server-monitor)

## Enable-VRisingServerMonitor

Alias: **vrenable**

```pwsh
vrenable [ShortNames or Servers]
```

Enables the server [Monitor](#monitor) for specified [Server](#server)(s).

### Arguments

- [ShortNames or Servers](#using-shortname-or-server): **Required**. The `Server(s)` to enable the monitor for.

### Examples

- [Enable Server Monitor](#enable-server-monitor)

## Get-VRisingServerManagerConfigOption

Alias: **vrmget**

```pwsh
vrmset [Option]
```

Retrieves specified [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption) value from the local machine.

### Arguments

- `Option`: **Required**. The name of the [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption) to retrieve.

## Set-VRisingServerManagerConfigOption

Alias: **vrmset**

```pwsh
vrmset [Option] [Value]
```

Modifies the value for specified [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption).

### Arguments

- `Option`: **Required**. The name of the [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption) to modify.

- `Value`: **Required**. The value to set the option to. 

### Examples

- [Set the Default Servers Folder](#set-the-default-servers-folder)

# Technical Details

VRising Server Manager orchestrates a series of process-tiers to monitor and manage each server.

The primary process tier is the interactive powershell process used when running `Import-VRisingServerManager`. In this process, the user can query and interact with multiple servers at once. Commands issued to servers are ran asynchronously by the secondary tier.

The secondary process tier contains the background processes used to asynchronously carry out commands against each server (known as 'Monitors'). One Monitor is launched per configured server. It polls the server configuration looking for a command to run, and processes the command if found.

The third-tier processes are the dedicated game server process and the update process (steamcmd). These processes are launched and monitored by the second tier.

Orchestrating the server processes involves issuing a command from the first tier, which sets the active command for the second tier. The secondary tier then reads this command, and orchestrates any actions against its resources, including starting or stopping any third tier processes, as needed.

Because the third and second tier processes are launched in the background, the user can safely close the interactive powershell window and the third and second tiers will continue running. New powershell sessions can discover the processes in the second and third tiers by reading the configuration file from disk where the process information is kept.

Configuration for servers is stored in json files in the `ProgramData` directory, which allows multiple instances of the manager to concurrently query and update server information such as the running process ID.

These configuration files are multi-process thread-safe across the application, with writes protected using named mutexes. This allows the use of automation to run manager commands from multiple sources without worrying about corrupting the state.

Server settings such as Host, Game, and Voip parameters are loaded from disk, converted into PSObjects, and combined with both their default values and any per-server overrides. Writes are then converted back to json on disk.

# Development

## Build Requirements

- PowerShell 5.1+

- [PowerShellGet](https://docs.microsoft.com/en-us/powershell/module/powershellget/)

- [psake](https://github.com/psake/psake)

## Building from source

1. Build the module

    ```
    Invoke-Psake
    ```

1. Add the repository root directory to your `PSModulePath` so that `Import-Module VRisingServerManager` can resolve successfully.

    **Note:** This assumes the current working directory is the repository root.

    ```
    $env:PSModulePath = "$($(pwd).Path);${env:PSModulePath}"
    ```

# License

see [LICENSE.txt](LICENSE.txt)
