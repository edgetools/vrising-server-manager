# V Rising Server Manager

Windows PowerShell cmdlets for easily managing multiple V Rising servers on a Windows machine

## Table of Contents

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

[Development](#development)

- [Build Requirements](#build-requirements)

- [Building from source](#building-from-source)

[License](#license)

# Requirements

Requires **PowerShell 5.1** or greater

Tested with

- Windows Server 2019
- Windows 11

*Note: other platforms may also work that meet the minimum requirements, but have not been tested.*

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
