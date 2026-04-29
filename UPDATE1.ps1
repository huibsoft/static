$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

if (-not $isAdmin) {
    Write-Host "Please run this script as administrator!" -ForegroundColor Red
    pause
    exit 1
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
Write-Host "Windows updates have been delayed until 2999 (effectively disabled)!" -ForegroundColor Cyan
Write-Host ""

pause