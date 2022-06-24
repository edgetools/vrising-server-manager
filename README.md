# V Rising Server Manager

Windows PowerShell cmdlets for easily managing multiple dedicated V Rising servers on a Windows machine

## Features

- Out-of-box support for PowerShell 5.1+ (already included in most modern Windows installations)

- Servers run in their own process so you can close the PowerShell window

- Automatically update server on start

- Automatically restart servers on a schedule

- Send system messages to players in-game (and automatically on restart)

- Search for and customize Game, Host, and Voip settings

- Read and tail log files

- Rotate and archive log files

- Archive save files

# Table of Contents

[Requirements](#requirements)

[Installation](#installation)

- [Install from PowerShellGallery](#install-from-powershellgallery)

- [Install from source](#install-from-source)

[Usage](#usage)

- [Create a new Server](#create-a-new-server)

- [Import an existing Server](#import-an-existing-Server)

- [Check Server status](#check-server-status)

- [Update Server](#update-server)

- [Start Server](#start-server)

- [Stop Server](#stop-server)

- [Restart Server](#restart-server)

- [Send a System Message](#send-a-system-message)

- [Remove Server](#remove-server)

[Concepts](#concepts)

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

[Technical Details](#technical-details)

[Development](#development)

- [Build Requirements](#build-requirements)

- [Building from source](#building-from-source)

[License](#license)

# Requirements

Requires **PowerShell 5.1** or greater (Targeting Windows Server 2019, Windows 10 and Newer)

Tested with

- Windows Server 2019
- Windows 11

Other platforms may also work that meet the minimum requirements, but have not been tested.

# Installation

## Install from PowerShellGallery

```
Install-Module VRisingServerManager
```

OR

## Install from source

Follow the instructions below for [Building from source](#Building-from-source)

Copy the module folder into a [supported module path](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module)

# Usage

*Tip: VRising Server Manager never deletes a server installation, game settings, or save data when removing a [Server](#server) configuration. You may safely delete and re-create or re-import a [Server](#server) configuration at any time.*

## Set the Default Server Folder

When new servers are created, their [InstallDir](#installdir), [DataDir](#datadir), and [LogDir](#logdir) are automatically configured as a subfolder of [DefaultServerDir](#defaultserverdir) named after their [ShortName](#shortname) (e.g. `D:\VRisingServers\MyServer`)

*Tip: if you prefer to put an `InstallDir`, `LogDir`, or `DataDir` elsewhere, you can also customize the specific values of each server after creation.*

```
vrmset DefaultServerDir D:\ExamplePath\ForAllServers
```

## Create a new Server

*Note: the name must be a [ShortName](#shortname) - you can customize the [DisplayName](#displayname) after creation.*

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

# Concepts

## DefaultServerDir

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

## Import-VRisingServer

Alias: **vrimport**

Creates new [Server](#server) configuration with the specified [ShortName](#shortname), using paths from an existing server on the local machine.

## Get-VRisingServer

Alias: **vrget**

Retrieves all or specified [Server](#server) configurations from the local machine, or retrieves a [Setting](#setting).

## Set-VRisingServer

Alias: **vrset**

Modifies or resets the value of a [Setting](#setting) for specified [Server](#server)(s).

## Start-VRisingServer

Alias: **vrstart**

Starts specified [Server](#server)(s), including orchestrating [UpdateOnStartup](), if enabled.

## Stop-VRisingServer

Alias: **vrstop**

Stops specified [Server](#server)(s), including orchestrating [AnnounceShutdown]() and [ShutdownDelay]() if enabled.

## Update-VRisingServer

Alias: **vrupdate**

Updates specified [Server](#server)(s) using [steamcmd]()

## Send-VRisingServerMessage

Alias: **vrsay**

Sends [Server](#server)(s) a system message using [mcrcon]()

## Remove-VRisingServer

Alias: **vrdelete**

Removes specified [Server](#server) configuration(s) from the local machine.

Does not remove the [InstallDir](#installdir), [DataDir](#datadir), or [LogDir](#logdir) which must be manually deleted if you wish to completely uninstall a server installation.

# Technical Details

VRising Server Manager orchestrates a series of process-tiers to monitor and manage each server.

The primary process tier is the interactive powershell process used when running `Import-VRisingServerManager`. In this process, the user can query and interact with multiple servers at once. Commands issued to servers are ran asynchronously by the secondary tier.

The secondary process tier contains the background processes used to asynchronously carry out commands against each server. One background process is launched per configured server while a command is running (or the server is running). It continuously polls the state of the server configuration looking for commands in the queue, and processes them once available. Once the server is stopped or the current command finishes executing, the background process dies.

The third-tier processes are the server application processes and the update processes (steamcmd). These processes are launched and monitored by the second tier.

Orchestrating the server processes involves issuing commands from the first tier, which writes commands into the command queue for each server. The secondary tier then reads these commands from the queue, and orchestrates any actions against its resources, including starting or stopping any third tier processes, as needed.

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
