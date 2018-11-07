#Requires -RunAsAdministrator
Param(
    $SiteName = "sitecorecomms",
    $ScPackageId = "Stroben.SitecoreDevOps.AppVeyor.V902XP0",
    $ScTools = "$PSScriptRoot\$ScPackageId\tools",
	$DownloadBase = $Env:DownloadBase,
	$DownloadDir = "C:\Downloads",
	$NpmName = "npm-Sitecore 9.0.2 rev. 180604.zip",
	$NpmUrl = "$DownloadBase/$NpmName",
    $NpmZip = "$DownloadDir\$NpmName",
    $CourierUrl = "https://github.com/adoprog/Sitecore-Courier/releases/download/1.2.4/Sitecore.Courier.Runner.zip",
    $CourierZip = "$DownloadDir\Sitecore.Courier.Runner.zip",
    $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe",
    $Configuration = "Release"
)

cd $PSScriptRoot
$ErrorActionPreference = "Stop"
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
	$ErrorActionPreference = "Stop"

    npm run dev
} Finally {
    Pop-Location
    $ErrorActionPreference = "Stop"
}

robocopy /e /NFL /NDL /NJH /NJS /nc /ns /np $serializationDir "$outputDir\web"
robocopy /e /NFL /NDL /NJH /NJS /nc /ns /np "$srcDir\Web\App_Config" "$outputDir\web\App_Config"

New-Item -Type Directory "$outputDir\web\bin"
Copy-Item "$srcDir\Web\bin\SitecoreComms.*.dll" "$outputDir\web\bin\"
Copy-Item "$srcDir\Web\bin\SitecoreComms.*.pdb" "$outputDir\web\bin\"

New-Item -Type Directory "$outputDir\web\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms"
Copy-Item "$srcDir\Angular\dist\*.js" "$outputDir\web\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms\"

InstallSitecoreCourier $CourierUrl $CourierZip
& $PSScriptRoot\Courier\Sitecore.Courier.Runner.exe -t $outputDir\Web -o $outputDir\SitecoreComms.ExecuteRightToBeForgotten.update -r -f

# TODO: Repair Metadata