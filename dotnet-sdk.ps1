
function ShowHelp () {
    $helpMessage = @"
.NET Core SDK Switcher and Installer

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
"@
    Write-Host $helpMessage
}


$releasesIndexUrl = "https://raw.githubusercontent.com/dotnet/core/master/release-notes/releases-index.json"


if($args.Count -eq 0) {
    ShowHelp
    return
}

$command = $args[0].ToString().ToLowerInvariant()

switch ($command) {
    "help" {  
        ShowHelp
    }
    "current" {
        dotnet --version
    }
    "list" {
        Write-Host "The installed .NET Core SDKs are:`n"
        Get-ChildItem "$env:programfiles\dotnet\sdk" | ForEach-Object { $_.Name}
    }
    "latest" {
        if (Test-Path "./global.json") { Remove-Item "./global.json" -Force | Out-Null }
        if (Test-Path "../global.json") {
            $deleteParentGlobalJson = Read-Host -Prompt "There's a global.json in your parent directory. Do you want to delete it? (N/y)"
            if ($deleteParentGlobalJson.ToLowerInvariant() -eq "y") {
                Remove-Item "../global.json" -Force | Out-Null
            } else {
                $currentVersion = (dotnet --version)
                Write-Host ".NET Core SDK current version: $currentVersion"
                return
            }
        }
        Write-Host ".NET Core SDK version switched to latest version."
        dotnet --version
    }
    "releases" {
        $oldProgressPreference = $progressPreference
        $progressPreference = 'SilentlyContinue'
        $releases = (Invoke-WebRequest -UseBasicParsing -Uri $releasesIndexUrl).Content | ConvertFrom-Json
        $releases.'releases-index' | Sort-Object -Property 'channel-version' -Unique -Descending | ForEach-Object {
            [pscustomobject]@{
                Version = $_.'channel-version'
                LatestReleaseDate = $_.'latest-release-date'
                LatestRelease = $_.'latest-release'
                LatestSdk = $_.'latest-sdk'
                LatestRuntime = $_.'latest-runtime'
                SupportPhase = $_.'support-phase'
                EndOfLifeDate = $_.'eol-date'
            }
        } | Format-Table
        $progressPreference = $oldProgressPreference
    }    
    "all-releases" {
        $oldProgressPreference = $progressPreference
        $progressPreference = 'SilentlyContinue'
        $releases = (Invoke-WebRequest -UseBasicParsing -Uri $releasesIndexUrl).Content | ConvertFrom-Json
        $releaseMetadata = $releases.'releases-index' | Sort-Object -Property 'channel-version' -Unique -Descending | ForEach-Object {
            [pscustomobject]@{
                Version = $_.'channel-version'
                LatestReleaseDate = $_.'latest-release-date'
                LatestRelease = $_.'latest-release'
                LatestSdk = $_.'latest-sdk'
                LatestRuntime = $_.'latest-runtime'
                SupportPhase = $_.'support-phase'
                EndOfLifeDate = $_.'eol-date'
                ReleasesJson = $_.'releases.json'
            }
        }
        $allReleases = @()
        $releaseMetadata | ForEach-Object {
            $versionReleases = (Invoke-WebRequest -UseBasicParsing -Uri $_.ReleasesJson).Content | ConvertFrom-Json
            $allReleases += $versionReleases.releases | Sort-Object -Property 'release-version' -Unique -Descending | ForEach-Object {
                # Write-Host $_.sdk.files
                # Write-Host $_
                [pscustomobject]@{
                    Version = $_.sdk.version
                    ReleaseDate = $_.'release-date'
                }
            }
        }
        $allReleases | Format-Table
        $progressPreference = $oldProgressPreference
    }        
    "get" {
        if(-not $args[1]) {
            Write-Host "Please specify .Net Core SDK version. Use 'dotnet sdk all-releases' to see valid versions."
        } 
        $oldProgressPreference = $progressPreference
        $progressPreference = 'SilentlyContinue'
        $releases = (Invoke-WebRequest -UseBasicParsing -Uri $releasesIndexUrl).Content | ConvertFrom-Json
        $releaseMetadata = $releases.'releases-index' | Sort-Object -Property 'channel-version' -Unique -Descending | ForEach-Object {
            [pscustomobject]@{
                Version = $_.'channel-version'
                LatestReleaseDate = $_.'latest-release-date'
                LatestRelease = $_.'latest-release'
                LatestSdk = $_.'latest-sdk'
                LatestRuntime = $_.'latest-runtime'
                SupportPhase = $_.'support-phase'
                EndOfLifeDate = $_.'eol-date'
                ReleasesJson = $_.'releases.json'
            }
        }
        
        $allReleases = @()
        $releaseMetadata | ForEach-Object {
            $versionReleases = (Invoke-WebRequest -UseBasicParsing -Uri $_.ReleasesJson).Content | ConvertFrom-Json
            $allReleases += $versionReleases.releases | Sort-Object 'Version' -Descending | ForEach-Object {
                
                # Write-Host $_
                [pscustomobject]@{
                    Version = $_.sdk.version
                    ReleaseDate = $_.'release-date'
                    File = $_.sdk.files
                }
            }
        }

        $platform = 'win-x64'
        $binaryType = "exe"
        if($args[2]) { $platform = $args[2] }
        if($args[3]) { $binaryType = $args[3] }
        if($args[1] -eq "latest") {
            $version = ($allReleases | Sort-Object 'Version' -Descending | Select-Object -First 1).Version
        } else {
            $version = $args[1]
        }

        $foundVersion = $allReleases | Where-Object {$_.Version -eq $version}
        if($foundVersion) {
            Write-Host "Installing $version ($platform)"
            $downloadUri = ($foundVersion.File | Where-Object {$_.rid -eq $platform -and $_.name.Contains(".$binaryType")}).url
            $downloadName = ($foundVersion.File | Where-Object {$_.rid -eq $platform -and $_.name.Contains(".$binaryType")}).name
            $downloadName = "$env:tmp/$version.$downloadName"
            Invoke-WebRequest -UseBasicParsing -Uri $downloadUri -OutFile $downloadName
            if(Test-Path $downloadName) {
                Start-Process -FilePath $downloadName
            } else {
                Write-Host "Error downloading from ($downloadUri) to ($downloadName) please try again"
            }
        } else {
            Write-Host "Please specify a valid .Net Core SDK version. Use 'dotnet sdk all-releases' to see valid versions."
        }

        $progressPreference = $oldProgressPreference
    }
    Default {
        $avaliableVersions = Get-ChildItem "$env:programfiles\dotnet\sdk" | ForEach-Object { $_.Name}
        if($command -in $avaliableVersions) {
            Write-Host "Switching .NET Core SDK version to $command"
            $globalJsonContent = @"
{
  "sdk": {
    "version": "$command"
  }
}
"@            
            $globalJsonContent | Set-Content -Path "./global.json"
        } else {
            Write-Host "The $command version of .Net Core SDK was not found"
            Write-Host "Please, run 'dotnet sdk list' to make sure you have it installed in '$env:programfiles\dotnet\sdk'"

        }
    }
}
