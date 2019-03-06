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
    [Parameter(Mandatory=$true)] [string] $NpmUrl,
    [Parameter(Mandatory=$true)] [string] $NpmZip
) {
	Write-Host "Installing Sitecore NPM" -ForegroundColor Green
	if (Test-Path -Path node_modules\sitecore) {
        Write-Debug "Already exists"
		Return
    }

	New-Item -ItemType Directory node_modules -ErrorAction SilentlyContinue
	New-Item -ItemType Directory node_modules\sitecore -ErrorAction SilentlyContinue

	if (!(Test-Path -Path $NpmZip)) {
		Start-BitsTransfer -Source $NpmUrl -Destination $NpmZip
	}

	Expand-Archive $NpmZip -DestinationPath node_modules\sitecore\

	npm install
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
    [Parameter(Mandatory=$true)] [string] $AngularDir,
    [Parameter(Mandatory=$true)] [string] $NpmUrl,
    [Parameter(Mandatory=$true)] [string] $NpmZip
) {
    Try {
        $ErrorActionPreference = "Continue"
        Push-Location $AngularDir
        Install-SitecoreNpmModules $NpmUrl $NpmZip
        npm run dev
    } Finally {
        Pop-Location
        $ErrorActionPreference = "Stop"
    }
}