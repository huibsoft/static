$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

if (-not $isAdmin) {
    Write-Host "请以管理员身份运行此脚本！" -ForegroundColor Red
    pause
    exit 1
}

$regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
    Write-Host "创建注册表路径：$regPath" -ForegroundColor Yellow
}

Set-ItemProperty -Path $regPath -Name "FlightSettingsMaxPauseDays" -Value "7152" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseFeatureUpdatesStartTime" -Value "2024-01-01T10:00:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseFeatureUpdatesEndTime" -Value "2999-12-01T09:59:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesStartTime" -Value "2024-01-01T10:00:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesEndTime" -Value "2999-12-01T09:59:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseUpdatesStartTime" -Value "2024-01-01T09:59:52Z" -Type String -Force
Set-ItemProperty -Path $regPath -Name "PauseUpdatesExpiryTime" -Value "2999-12-01T09:59:52Z" -Type String -Force

Write-Host ""
Write-Host "禁用更新，操作完成！" -ForegroundColor Cyan
Write-Host ""

pause