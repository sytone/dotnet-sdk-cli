# dotnet-sdk-cli

Adds a sdk command to the dotnet CLI tool to help with SDK download and version management

## Installation

Copy the `dotnet-sdk.cmd` and `dotnet-sdk.ps1` files to a folder that is on your path use `$env:path` in powershell to validate location.

## Usage

``` Text
dotnet sdk [command]
dotnet sdk [version]
dotnet sdk get [version] [platform] [binarytype]

 Basic Commands:
   latest        Switches to the latest .NET Core SDK version
   list          Lists all installed .NET Core SDKs
   releases      Lists all available major releases of .NET Core SDKs
   all-releases  Lists all available releases of .NET Core SDKs
   help          Display help

 Set Version:
   An installed version number of a .NET Core SDK. This will be set as the default for this path using global.json.
 
 Get Version:
   Downloads the provided release version.
    Options:
      version        'latest' for the latest release or a version from all-releases
      platform       By default it is 'win-x64'
      binarytype     By default it is 'exe'
 
 
```
