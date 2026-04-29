# 需要以管理员身份运行此脚本
# 保存为 .ps1 文件，右键点击选择“使用 PowerShell 运行”

# 严格模式，帮助捕获潜在错误
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $PSCommandPath + "`""
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
    } catch {
        throw "Failed to elevate to Administrator: $_"
    }
    exit 0
}

$regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
    Write-Host "Created registry path: $regPath" -ForegroundColor Yellow
}

Set-ItemProperty -Path $regPath -Name "FlightSettingsMaxPauseDays" -Value "7152" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseFeatureUpdatesStartTime" -Value "2024-01-01T10:00:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseFeatureUpdatesEndTime" -Value "2999-12-01T09:59:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesStartTime" -Value "2024-01-01T10:00:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesEndTime" -Value "2999-12-01T09:59:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseUpdatesStartTime" -Value "2024-01-01T09:59:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseUpdatesExpiryTime" -Value "2999-12-01T09:59:52Z" -Type String -Force

Write-Host ""
Write-Host "Successfully disabled automatic updates for Windows 11." -ForegroundColor Green
Write-Host ""

pause