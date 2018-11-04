Function EnableModernSecurityProtocols() {
    Write-Host "Enabling modern security protocols..." -foregroundcolor "green"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
}

Function IdentifyMsBuild(
    [Parameter(Mandatory=$true)] [string] $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"
) {
    Write-Host "Identify msbuild" -ForegroundColor Green
    Write-Host "Supplied location: $msbuild ... " -ForegroundColor Yellow -NoNewline
    if (Test-Path -Path $msbuild) {
        Write-Host "Found!"
    } else {
        Write-Debug "Not found!"
        $msbuild = $(cmd /c where msbuild)

        if ($msbuild -and (Test-Path -Path $msbuild)) {
            Write-Host "Updated path to $msbuild" -ForegroundColor Yellow
        } else {
            throw "Cannot find msbuild"
        }
    }
}

Function InstallSitecoreCourier(
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
        EnableModernSecurityProtocols
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($CourierUrl, $CourierZip)
    }

    Expand-Archive $CourierZip -DestinationPath $target
}

Function InitOutputDir() {
    $outputDir = "$PSScriptRoot\..\output"
    Remove-Item $outputDir -Force -Recurse -ErrorAction Ignore | Out-Null
    New-Item -Type Directory $outputDir | Out-Null
    $outputDir = Resolve-Path $outputDir
    return $outputDir
}