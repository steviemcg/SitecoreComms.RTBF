#Requires -RunAsAdministrator
Param(
    [Parameter(Mandatory=$false)] [string] $SiteName = "sitecorecomms",
	[Parameter(Mandatory=$false)] [string] $DownloadBase = $Env:DownloadBase,
	[Parameter(Mandatory=$false)] [string] $DownloadDir = "C:\Downloads",
	[Parameter(Mandatory=$false)] [string] $NpmName = "npm-Sitecore 9.1.0 rev. 001564.zip",
	[Parameter(Mandatory=$false)] [string] $NpmUrl = "$DownloadBase/$NpmName",
    [Parameter(Mandatory=$false)] [string] $NpmZip = "$DownloadDir\$NpmName",
    [Parameter(Mandatory=$false)] [string] $CourierUrl = "https://github.com/adoprog/Sitecore-Courier/releases/download/1.2.4/Sitecore.Courier.Runner.zip",
    [Parameter(Mandatory=$false)] [string] $CourierZip = "$DownloadDir\Sitecore.Courier.Runner.zip",
    [Parameter(Mandatory=$false)] [string] $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe",
    [Parameter(Mandatory=$false)] [string] $Configuration = "Release",
    [Parameter(Mandatory=$false)] [string] $SonarToken = "b439320dd48f2f49a745e7edeb23ca4a3d3ef4b0"
)

$ErrorActionPreference = "Stop"
Import-Module $PSScriptRoot\build.psm1 -Force

Try 
{
    Push-Location $PSScriptRoot
    $srcDir = Resolve-Path ..\src
    $angularDir = Resolve-Path "$srcDir\Angular"

    Invoke-DownloadAssets -DownloadBase $DownloadBase -DownloadDir $DownloadDir -CourierUrl $CourierUrl -CourierZip $CourierZip -NpmUrl $NpmUrl -NpmZip $NpmZip -AngularDir $angularDir
    Invoke-DotNetBuild -Solution "$srcDir\SitecoreComms.RTBF.sln" -SonarToken $SonarToken -Configuration $Configuration -msbuild $msbuild
    Invoke-AngularBuild -AngularDir $angularDir
    Invoke-BuildArtifacts -srcDir $srcDir -Configuration $Configuration
} Finally {
    Pop-Location
}