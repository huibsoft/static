# ===============================
# Windows 11 ARM 网络修复脚本 (Parallels Desktop)
# ===============================

Write-Host "=== Windows 11 ARM Network Repair Script ===" -ForegroundColor Cyan

# Check for administrator privileges
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator"))
{
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    exit
}

# ===============================
# 步骤 1: 关闭网络适配器电源管理
# ===============================
Write-Host "`nStep 1: Attempting to disable network adapter power management..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object {$_.Status -ne "Disconnected"}

foreach ($adapter in $adapters) {
	Write-Host "Processing Parallels virtual network adapter: " -NoNewline
    Write-Host "$($adapter.InterfaceDescription)" -ForegroundColor Green
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\"
        $key = Get-ChildItem $regPath -ErrorAction SilentlyContinue | Where-Object {
            ($props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue)
            $props -and $props.NetCfgInstanceId -eq $adapter.InterfaceGuid
        }
        if ($key) {
            Set-ItemProperty -Path $key.PSPath -Name "PnPCapabilities" -Value 24 -ErrorAction SilentlyContinue
            Write-Host "Disabled power management" -ForegroundColor Green
        } else {
            Write-Host "Cannot access registry key, skipping power management settings" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error processing adapter, skipping..." -ForegroundColor Yellow
    }
}

# ===============================
# 步骤 2: 重置网络配置
# ===============================
Write-Host "`nStep 2: Resetting network adapter..." -ForegroundColor Yellow
try {
    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null
    ipconfig /flushdns | Out-Null
    Write-Host "Network adapter reset" -ForegroundColor Green
} catch {
    Write-Host "Network reset failed, skipping..." -ForegroundColor Yellow
}

# ===============================
# 步骤 3: 安全重启网络服务
# ===============================
Write-Host "`nStep 3: Attempting to restart network services..." -ForegroundColor Yellow
$services = @("Dhcp", "Dnscache", "Netman", "NlaSvc")

foreach ($svc in $services) {
    try {
        $service = Get-Service -Name $svc -ErrorAction Stop
        if ($service.Status -eq "Running" -and $service.CanStop) {
            Restart-Service -Name $svc -ErrorAction Stop
            Write-Host "Service $svc restarted" -ForegroundColor Green
        } else {
            Write-Host "Service $svc cannot be stopped or does not need restart, skipped" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Service $svc cannot be accessed or stopped, safely skipped" -ForegroundColor Yellow
    }
}

Write-Host "`nRepair completed!" -ForegroundColor Green
Write-Host "Please restart the virtual machine to apply all changes" -ForegroundColor Cyan