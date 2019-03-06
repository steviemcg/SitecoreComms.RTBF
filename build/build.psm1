Function Enable-ModernSecurityProtocols() {
    Write-Host "Enabling modern security protocols..." -foregroundcolor "green"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
}

Function Invoke-IdentifyMsBuild(
    [Parameter(Mandatory=$true)] [string] $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"
) {
    if (Test-Path -Path $msbuild) {
        return $msbuild
    } else {
        $msbuild = $(cmd /c where msbuild)

        if ($msbuild -and (Test-Path -Path $msbuild)) {
            return $msbuild
        } else {
            throw "Cannot find msbuild"
        }
    }
}

Function Install-SitecoreNpmModules(
    [Parameter(Mandatory=$true)] [string] $AngularDir,
    [Parameter(Mandatory=$true)] [string] $NpmUrl,
    [Parameter(Mandatory=$true)] [string] $NpmZip
) {
    Try {
        Push-Location $AngularDir

        Write-Host "Installing Sitecore NPM..." -ForegroundColor Green
        if (Test-Path -Path node_modules\sitecore) {
            Write-Debug "Already exists"
            Return
        }

        New-Item -ItemType Directory Angular\node_modules -ErrorAction SilentlyContinue
        New-Item -ItemType Directory Angular\node_modules\sitecore -ErrorAction SilentlyContinue

        if (!(Test-Path -Path $NpmZip)) {
            Start-BitsTransfer -Source $NpmUrl -Destination $NpmZip
        }

        Expand-Archive $NpmZip -DestinationPath Angular\node_modules\sitecore\

        npm install
    } Finally {
        Pop-Location
    }
}

Function Install-SitecoreCourier(
    [Parameter(Mandatory=$true)] [string] $CourierUrl,
    [Parameter(Mandatory=$true)] [string] $CourierZip
) {
    $target = "$PSScriptRoot\Courier"
    Write-Host "Installing Sitecore Courier to $target" -ForegroundColor Green
    
    if (Test-Path -Path $target) {
        Write-Debug "Already exists"
        return
    }
    
    Write-Host "Installing $CourierUrl to $CourierZip" -ForegroundColor Green
    if (Test-Path -Path $CourierZip) {
        Write-Debug "Already exists"
    } else {
        # Start-BitsTransfer sadly not compatible with Github Releases?
		# so resort to System.Net.WebClient

		Enable-ModernSecurityProtocols
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($CourierUrl, $CourierZip)
    }

    Expand-Archive $CourierZip -DestinationPath $target
}

Function Initialize-OutputDir() {
    $outputDir = "$PSScriptRoot\..\output"
    Remove-Item $outputDir -Force -Recurse -ErrorAction Ignore | Out-Null
    New-Item -Type Directory $outputDir | Out-Null
    $outputDir = Resolve-Path $outputDir
    return $outputDir
}

Function Invoke-DownloadAssets(
    [Parameter(Mandatory=$true)] [string] $DownloadBase,
    [Parameter(Mandatory=$true)] [string] $DownloadDir,
    [Parameter(Mandatory=$true)] [string] $CourierUrl,
    [Parameter(Mandatory=$true)] [string] $CourierZip,
    [Parameter(Mandatory=$true)] [string] $NpmUrl,
    [Parameter(Mandatory=$true)] [string] $NpmZip,
    [Parameter(Mandatory=$true)] [string] $AngularDir
) {
    Write-Host "Downloading assets..." -foregroundcolor "green"
    New-Item -Type Directory $DownloadDir -ErrorAction Ignore
    Install-SitecoreNpmModules -NpmUrl $NpmUrl -NpmZip $NpmZip -AngularDir $AngularDir
    Install-SitecoreCourier -CourierUrl $CourierUrl -CourierZip $CourierZip
}

Function Invoke-DotNetBuild(
    [Parameter(Mandatory=$true)] [string] $Solution,
    [Parameter(Mandatory=$true)] [string] $SonarToken,
    [Parameter(Mandatory=$true)] [string] $Configuration,
    [Parameter(Mandatory=$true)] [string] $msbuild
) {
    nuget restore $Solution

    $msbuild = Invoke-IdentifyMsBuild $msbuild
    
    SonarScanner.MSBuild.exe begin /k:"steviemcg_SitecoreComms.RTBF" /o:"steviemcg-github" /d:sonar.host.url="https://sonarcloud.io" /d:sonar.login=$SonarToken
    & $msbuild -verbosity:m $Solution /p:Configuration=$Configuration
    SonarScanner.MSBuild.exe end /d:sonar.login=$SonarToken
    
    if (!($LastExitCode -eq "0")) {
        throw "Build failed with exit code $LastExitCode"
    }    
}

Function Invoke-AngularBuild(
    [Parameter(Mandatory=$true)] [string] $AngularDir
) {
    Try {
        $ErrorActionPreference = "Continue"
        Push-Location $AngularDir
        npm run dev
    } Finally {
        Pop-Location
        $ErrorActionPreference = "Stop"
    }
}

Function Invoke-BuildArtifacts(
    [Parameter(Mandatory=$true)] [string] $srcDir,
    [Parameter(Mandatory=$true)] [string] $Configuration
) {
    $outputDir = Initialize-OutputDir
    
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
    $serializationDir = Resolve-Path ..\serialization
    robocopy /e /NFL /NDL /NJH /NJS /nc /ns /np $serializationDir "$outputDir\web"
    robocopy /e /NFL /NDL /NJH /NJS /nc /ns /np "$srcDir\Web\App_Config" "$outputDir\web\App_Config"
    Remove-Item "$outputDir\web\App_Config\Include\SitecoreComms\RTBF\Unicorn.Configs.config"

    New-Item -Type Directory "$outputDir\web\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms"
    Copy-Item "$srcDir\Angular\dist\*.js" "$outputDir\web\sitecore\shell\client\Applications\MarketingAutomation\plugins\SitecoreComms\"

    New-Item -Type Directory "$outputDir\web\bin"
    Copy-Item "$srcDir\Web\bin\SitecoreComms.*.dll" "$outputDir\web\bin\"
    Copy-Item "$srcDir\Web\bin\SitecoreComms.*.pdb" "$outputDir\web\bin\"

    & $PSScriptRoot\Courier\Sitecore.Courier.Runner.exe -t $outputDir\Web -o $outputDir\SitecoreComms.ExecuteRightToBeForgotten.update -r -f

    # TODO: Repair Metadata

    Compress-Archive -Path "$outputDir\AutomationEngine\*" -DestinationPath "$outputDir\SitecoreComms.ExecuteRightToBeForgotten.AutomationEngine.zip"
    Compress-Archive -Path "$outputDir\IndexWorker\*" -DestinationPath "$outputDir\SitecoreComms.ExecuteRightToBeForgotten.IndexWorker.zip"
    Compress-Archive -Path "$outputDir\XConnect\*" -DestinationPath "$outputDir\SitecoreComms.ExecuteRightToBeForgotten.XConnect.zip"
}