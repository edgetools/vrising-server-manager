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

- (Coming Soon!) Send system messages to players in-game from the console

- Automatically send system messages on restart or shutdown

- Automatically restart servers on a schedule

- Rotate and archive log files

- Archive save files

# Release Notes

<!-- begin release notes -->
## [0.4.0](https://www.github.com/edgetools/vrising-server-manager/compare/0.3.0...0.4.0) (2022-07-15)

### Features

* vrrestart and UpdateOnStartup ([ad47c47](https://www.github.com/edgetools/vrising-server-manager/commit/ad47c472fc0d7d122ec8982ed4d38e5d6ba7b37a))
<!-- end release notes -->

# Table of Contents

[Requirements](#requirements)

[Installation](#installation)

- [Install from PowerShellGallery](#install-from-powershellgallery)

- [Install from source](#install-from-source)

[Usage](#usage)

- [Import the module](#import-the-module)

- [Set the Default Server Folder](#set-the-default-server-folder)

- [Create a new Server](#create-a-new-server)

- [Import an existing Server](#import-an-existing-Server)

- [Check Server status](#check-server-status)

- [Update Server](#update-server)

- [Start Server](#start-server)

- [Stop Server](#stop-server)

- [Restart Server](#restart-server)

- [Send a System Message](#send-a-system-message)

- [Remove Server](#remove-server)

- [Disable Server Monitor](#disable-server-monitor)

- [Enable Server Monitor](#enable-server-monitor)

- [Update Server Manager](#update-server-manager)

[Concepts](#concepts)

- [VRisingServerManagerFlags](#vrisingservermanagerflags)

- [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption)

    - [SkipNewVersionCheck](#skipnewversioncheck)

    - [DefaultServerDir](#defaultserverdir)

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

[Command Reference](#command-reference)

- [New-VRisingServer](#new-vrisingserver)

- [Import-VRisingServer](#import-vrisingserver)

- [Get-VRisingServer](#get-vrisingserver)

- [Set-VRisingServer](#set-vrisingserver)

- [Start-VRisingServer](#start-vrisingserver)

- [Stop-VRisingServer](#stop-vrisingserver)

- [Update-VRisingServer](#update-vrisingserver)

- [Send-VRisingServerMessage](#send-vrisingservermessage)

- [Remove-VRisingServer](#remove-vrisingserver)

- [Get-VRisingServerManagerConfigOption](#get-vrisingservermanagerconfigoption)

- [Set-VRisingServerManagerConfigOption](#set-vrisingservermanagerconfigoption)

- [Disable-VRisingServer](#enable-vrisingserver)

- [Enable-VRisingServer](#enable-vrisingserver)

[Technical Details](#technical-details)

[Development](#development)

- [Build Requirements](#build-requirements)

- [Building from source](#building-from-source)

[License](#license)

# Requirements

Requires **PowerShell 5.1** or greater (Targeting Windows Server 2019, Windows 10 and Newer)

*Tip: Check your PowerShell version with `$PSVersionTable.PSVersion.ToString()`*

Tested with

- Windows Server 2019
- Windows 11

Other platforms may also work that meet the minimum requirements, but have not been tested.

# Installation

## Install from PowerShellGallery

```
Install-Module -Name VRisingServerManager
```

OR

## Install from source

Follow the instructions below for [Building from source](#Building-from-source)

Copy the module folder into a [supported module path](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module)

# Usage

*Tip: VRising Server Manager never deletes a server installation, game settings, or save data when removing a [Server](#server) configuration. You may safely delete and re-create or re-import a [Server](#server) configuration at any time.*

## Import the module

Before you can run commands, you first must import the module.

*Tip: Some module behavior can be temporarily customized using [VRisingServerManagerFlags](#vrisingservermanagerflags) prior to import*

```
Import-Module VRisingServerManager
```

## Set the Default Server Folder

When new servers are created, their [InstallDir](#installdir), [DataDir](#datadir), and [LogDir](#logdir) are automatically configured as a subfolder of [DefaultServerDir](#defaultserverdir) named after their [ShortName](#shortname) (e.g. `D:\VRisingServers\MyServer`)

*Tip: if you prefer to put the `InstallDir`, `LogDir`, or `DataDir` elsewhere, you can customize specific values for each server after creation.*

```
vrmset DefaultServerDir D:\ExamplePath\ForAllServers
```

You can also check the current [DefaultServerDir](#defaultserverdir) with [vrmget](#get-vrisingservermanagerconfigoption)

```
vrmget DefaultServerDir
```

## Create a new Server

*Note: this name must be a [ShortName](#shortname) and you can customize the [DisplayName](#displayname) after creation.*

```
vrcreate MyServer
```

## Import an existing Server

Answer the prompts for required information, or specify them directly on the command line.

```
vrimport MyServer
```

or

```
vrimport `
  -ShortName MyServer `
  -InstallDir C:\existing\path\to\install `
  -DataDir C:\existing\path\to\datadir `
  -LogDir C:\existing\path\to\logdir
```

## Check Server status

List all Servers

```
vrget
```

List a specific Server

```
vrget MyServer
```

## Update Server

*Tip: this can also be used for first-time installation*

Update all Servers

```
vrupdate
```

Update a specific Server

```
vrupdate MyServer
```

## Start Server

Start all Servers

```
vrstart
```

Start a specific Server

```
vrstart MyServer
```

## Stop Server

Stop all Servers

```
vrstop
```

Stop a specific Server

```
vrstop MyServer
```

## Restart Server

Restart all Servers

```
vrrestart
```

Restart a specific Server

```
vrrestart MyServer
```

## Send a System Message

Message all Servers

```
vrsay "This is a system message"
```

Message a specific Server

```
vrsay MyServer "This is a system message"
```

## Remove Server

*Note: to prevent unintentionally removing server data, this does not remove the [InstallDir](#installdir), [DataDir](#datadir), or [LogDir](#logdir) which must be manually deleted if you wish to completely uninstall a server installation.*

*If you accidentally remove a server, you can easily add it again with [vrcreate](#new-vrisingserver) or [vrimport](#import-vrisingserver).*

Remove all Servers

```
vrdelete
```

Remove a specific Server

```
vrdelete MyServer
```

## Disable Server Monitor

Disabling the server monitor process will cause it to shut down, but will still leave the server process running.

Disable all Server Monitors

```
vrdisable
```

Disable a specific Server Monitor

```
vrdisable MyServer
```

## Enable Server Monitor

Note: the server monitor automatically launches whenever running [Server](#server) commands.

Enable all Server Monitors

```
vrenable
```

Enable a specific Server Monitor

```
vrenable MyServer
```

## Update Server Manager

Steps to Update to a new version:

1. Stop (Disable) any running Monitor(s)
   ```
   vrdisable

   (VRisingServer) [foo] Monitor disabled
   ```
1. Wait for Monitor(s) to Stop, then verify Monitor(s) are "Disabled"
   ```
   vrget

   Status  Uptime Monitor
   ------  ------ -------
   Running 20h    Disabled
   ```
1. Update the Module
   ```
   Update-Module -Name VRisingServerManager
   ```
1. Exit the current PowerShell session
   
   The module is compiled during import, so you **must** open a new powershell session after upgrading to ensure the new version is loaded correctly.

   ```
   exit
   ```
1. Open a new PowerShell session
1. Import the Updated Module
   ```
   Import-Module VRisingServerManager
   ```
1. Start (Re-Enable) the Monitor(s)
   ```
   vrenable

   (VRisingServer) [foo] Monitor enabled
   (VRisingServer) [foo] Monitor launched
   ```
1. Verify the Monitor(s) are Running (Idle)
   ```
   vrget

   Status  Uptime Monitor
   ------  ------ -------
   Running 20h    Idle
   ```

# Concepts

## VRisingServerManagerFlags

Some module behavior can be temporarily customized by settings flags on `[hashtable] $VRisingServerManagerFlags` prior to import

Supported flags:

- `SkipNewVersionCheck`: Disables checking for new package versions when loading the module (see: [SkipNewVersionCheck](#skipnewversioncheck)).

Example:

```
$VRisingServerManagerFlags = @{
    SkipNewVersionCheck = $true
}
Import-Module VRisingServerManager
```

## VRisingServerManagerConfigOption

Some settings for the manager itself can be retrieved or modified using [vrmget](#get-vrisingservermanagerconfigoption) and [vrmset](#set-vrisingservermanagerconfigoption).

These settings are persisted to disk.

### SkipNewVersionCheck

The module will automatically check [PowerShellGallery](https://www.powershellgallery.com/packages/VRisingServerManager) for new versions of the module.

This behavior can be disabled by setting `SkipNewVersionCheck` to `$true`

- **type**: `boolean`

- **default**: `$false`

### DefaultServerDir

## Server

### ShortName

### DisplayName

### InstallDir

### DataDir

### LogDir

### UpdateOnStartup

### AnnounceShutdown

### ShutdownDelay

## Setting

# Command Reference

*Note: most commands have convenient aliases, which are automatically configured when importing the module. Command examples will use the alias, when available.*

## New-VRisingServer

Alias: **vrcreate**

Creates new [Server](#server) configuration on the local machine with the specified [ShortName](#shortname).

Example: [Create a new Server](#create-a-new-server)

## Import-VRisingServer

Alias: **vrimport**

Creates new [Server](#server) configuration with the specified [ShortName](#shortname), using paths from an existing server on the local machine.

Example: [Import an existing Server](#import-an-existing-server)

## Get-VRisingServer

Alias: **vrget**

Retrieves all or specified [Server](#server) configurations from the local machine, or retrieves a [Setting](#setting).

Example: [Check Server status](#check-server-status)

## Set-VRisingServer

Alias: **vrset**

Modifies or resets the value of a [Setting](#setting) for specified [Server](#server)(s).

## Start-VRisingServer

Alias: **vrstart**

Starts specified [Server](#server)(s), including orchestrating [UpdateOnStartup](#updateonstartup), if enabled.

Example: [Start Server](#start-server)

## Stop-VRisingServer

Alias: **vrstop**

Stops specified [Server](#server)(s), including orchestrating [AnnounceShutdown](#announceshutdown) and [ShutdownDelay](#shutdowndelay) if enabled.

Example: [Stop Server](#stop-server)

## Update-VRisingServer

Alias: **vrupdate**

Updates specified [Server](#server)(s) using [steamcmd]().

Example: [Update Server](#update-server)

## Send-VRisingServerMessage

Alias: **vrsay**

Sends [Server](#server)(s) a system message using [mcrcon]().

Example: [Send a System Message](#send-a-system-message)

## Remove-VRisingServer

Alias: **vrdelete**

Removes specified [Server](#server) configuration(s) from the local machine.

Does not remove the [InstallDir](#installdir), [DataDir](#datadir), or [LogDir](#logdir) which must be manually deleted if you wish to completely uninstall a server installation.

Example: [Remove Server](#remove-server)

## Disable-VRisingServer

Alias: **vrdisable**

Disables the server [Monitor](#monitor) for specified [Server](#server)

Example: [Disable Server Monitor](#disable-server-monitor)

## Enable-VRisingServer

Alias: **vrenable**

Enables the server [Monitor](#monitor) for specified [Server](#server)

Example: [Enable Server Monitor](#disable-server-monitor)

## Get-VRisingServerManagerConfigOption

Alias: **vrmget**

Retrieves specified [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption) value from the local machine.

## Set-VRisingServerManagerConfigOption

Alias: **vrmset**

Modifies the value for specified [VRisingServerManagerConfigOption](#vrisingservermanagerconfigoption).

# Technical Details

VRising Server Manager orchestrates a series of process-tiers to monitor and manage each server.

The primary process tier is the interactive powershell process used when running `Import-VRisingServerManager`. In this process, the user can query and interact with multiple servers at once. Commands issued to servers are ran asynchronously by the secondary tier.

The secondary process tier contains the background processes used to asynchronously carry out commands against each server (known as 'Monitors'). One Monitor is launched per configured server. It continuously polls the state of the server configuration looking for a command to run, and processes the command if found.

The third-tier processes are the server application processes and the update processes (steamcmd). These processes are launched and monitored by the second tier.

Orchestrating the server processes involves issuing a command from the first tier, which sets the active command for the second tier. The secondary tier then reads this command, and orchestrates any actions against its resources, including starting or stopping any third tier processes, as needed.

Because the third and second tier processes are launched in the background, the user can safely close the interactive powershell window and the third and second tiers will continue running. New powershell sessions can discover the processes in the second and third tiers by reading the configuration file from disk where the process information is kept.

Configuration for servers is stored in json files in the `ProgramData` directory, which allows multiple instances of the manager to concurrently query and update server information such as the running process ID.

These configuration files are multi-process thread-safe across the application, with writes protected using named mutexes. This allows the use of automation to run manager commands from multiple sources without worrying about corrupting the state.

Server settings such as Host, Game, and Voip parameters are loaded from disk, converted into PSObjects, and combined with both their default values and any per-server overrides. Writes are then converted back to json on disk.

# Development

## Build Requirements

- PowerShell 5.1+ (Targeting Windows Server 2019, Windows 10 and Newer)

- [PowerShellGet](https://docs.microsoft.com/en-us/powershell/module/powershellget/)

- [psake](https://github.com/psake/psake)

## Building from source

1. Build the module

    ```
    Invoke-Psake
    ```

1. Add the repository root directory to your `PSModulePath` so that `Import-Module VRisingServerManager` can resolve successfully

    *This assumes the current working directory is the repository root*

    ```
    $env:PSModulePath = "$($(pwd).Path);${env:PSModulePath}"
    ```

# License

see [LICENSE.txt](LICENSE.txt)
