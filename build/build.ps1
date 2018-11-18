#Requires -RunAsAdministrator
Param(
    [Parameter(Mandatory=$false)] [string] $SiteName = "sitecorecomms",
    [Parameter(Mandatory=$false)] [string] $ScPackageId = "Stroben.SitecoreDevOps.AppVeyor.V902XP0",
    [Parameter(Mandatory=$false)] [string] $ScTools = "$PSScriptRoot\$ScPackageId\tools",
	[Parameter(Mandatory=$false)] [string]  $DownloadBase,
	[Parameter(Mandatory=$false)] [string] $DownloadDir = "C:\Downloads",
	[Parameter(Mandatory=$false)] [string] $NpmName = "npm-Sitecore 9.0.2 rev. 180604.zip",
	[Parameter(Mandatory=$false)] [string] $NpmUrl = "$DownloadBase/$NpmName",
    [Parameter(Mandatory=$false)] [string] $NpmZip = "$DownloadDir\$NpmName",
    [Parameter(Mandatory=$false)] [string] $CourierUrl = "https://github.com/adoprog/Sitecore-Courier/releases/download/1.2.4/Sitecore.Courier.Runner.zip",
    [Parameter(Mandatory=$false)] [string] $CourierZip = "$DownloadDir\Sitecore.Courier.Runner.zip",
    [Parameter(Mandatory=$false)] [string] $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe",
    [Parameter(Mandatory=$false)] [string] $Configuration = "Release"
)

Set-Location $PSScriptRoot

$ErrorActionPreference = "Stop"
if (!$DownloadBase) {
    $DownloadBase = $Env:DownloadBase

    if (!$DownloadBase) {
        throw "DownloadBase parameter missing"
    }
}

Import-Module $PSScriptRoot\build.psm1 -DisableNameChecking -Force

$srcDir = Resolve-Path ..\src
$serializationDir = Resolve-Path ..\serialization
New-Item -Type Directory $DownloadDir -ErrorAction Ignore
$outputDir = InitOutputDir

nuget restore ..\src\SitecoreComms.RTBF.sln

$msbuild = IdentifyMsBuild $msbuild
& $msbuild -verbosity:m $srcDir\SitecoreComms.RTBF.sln /p:Configuration=$Configuration

if (!($LastExitCode -eq "0")) {
    throw "Build failed with exit code $LastExitCode"
}

Try {
    $ErrorActionPreference = "Continue"
    Push-Location "$srcDir\Angular"
	InstallSitecoreNpmModules $NpmUrl $NpmZip
    npm run dev
} Finally {
    Pop-Location
    $ErrorActionPreference = "Stop"
}

# Automation Engine
New-Item -Type Directory "$outputDir\AutomationEngine"
Copy-Item "$srcDir\Activities\bin\$Configuration\SitecoreComms.*.dll" "$outputDir\AutomationEngine\"
Copy-Item "$srcDir\Activities\bin\$Configuration\SitecoreComms.*.pdb" "$outputDir\AutomationEngine\"
robocopy /e /NFL /NDL /NJH /NJS /nc /ns /np "$srcDir\Activities\App_Data" "$outputDir\AutomationEngine\App_Data"

# Index Worker
New-Item -Type Directory "$outputDir\IndexWorker"
Copy-Item "$srcDir\Models\bin\$Configuration\SitecoreComms.*.dll" "$outputDir\IndexWorker\"

# XConnect
New-Item -Type Directory "$outputDir\XConnect"
Copy-Item "$srcDir\Models\bin\$Configuration\SitecoreComms.*.dll" "$outputDir\XConnect\"

# Web
robocopy /e /NFL /NDL /NJH /NJS /nc /ns /np $serializationDir "$outputDir\web"
robocopy /e /NFL /NDL /NJH /NJS /nc /ns /np "$srcDir\Web\App_Config" "$outputDir\web\App_Config"

New-Item -Type Directory "$outputDir\web\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms"
Copy-Item "$srcDir\Angular\dist\*.js" "$outputDir\web\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms\"

New-Item -Type Directory "$outputDir\web\bin"
Copy-Item "$srcDir\Web\bin\SitecoreComms.*.dll" "$outputDir\web\bin\"
Copy-Item "$srcDir\Web\bin\SitecoreComms.*.pdb" "$outputDir\web\bin\"

InstallSitecoreCourier $CourierUrl $CourierZip
& $PSScriptRoot\Courier\Sitecore.Courier.Runner.exe -t $outputDir\Web -o $outputDir\SitecoreComms.ExecuteRightToBeForgotten.update -r -f

# TODO: Repair Metadata

Compress-Archive -Path "$outputDir\AutomationEngine\*" -DestinationPath "$outputDir\SitecoreComms.ExecuteRightToBeForgotten.AutomationEngine.zip"
Compress-Archive -Path "$outputDir\IndexWorker\*" -DestinationPath "$outputDir\SitecoreComms.ExecuteRightToBeForgotten.IndexWorker.zip"
Compress-Archive -Path "$outputDir\XConnect\*" -DestinationPath "$outputDir\SitecoreComms.ExecuteRightToBeForgotten.XConnect.zip"