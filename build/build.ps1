Param(
    $CourierUrl = "https://github.com/adoprog/Sitecore-Courier/releases/download/1.2.4/Sitecore.Courier.Runner.zip",
    $DownloadDir = "C:\Downloads",
    $CourierZip = "$DownloadDir\Sitecore.Courier.Runner.zip",
    $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe",
    $Configuration = "Release"
)

Import-Module $PSScriptRoot\build.psm1 -DisableNameChecking -Force

$srcDir = Resolve-Path ..\src
$serializationDir = Resolve-Path ..\serialization
New-Item -Type Directory $DownloadDir -ErrorAction Ignore
$outputDir = InitOutputDir

IdentifyMsBuild $msbuild

& $msbuild -verbosity:m $srcDir\SitecoreComms.RTBF.sln /p:Configuration=$Configuration

Try {
    Push-Location "$srcDir\Angular"
    npm run dev
} Finally {
    Pop-Location
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