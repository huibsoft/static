# ============================================
# Windows 优化工具箱 - 菜单选择版
# 功能：禁用更新 | 禁用安全中心 | 经典右键菜单 | 激活Windows | 内存清理
# 注意：必须以管理员身份运行
# ============================================

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "错误：请以管理员身份运行此脚本！" -ForegroundColor Red
    Write-Host "右键点击 PowerShell -> 以管理员身份运行" -ForegroundColor Yellow
    pause
    exit
}

# 定义各功能的执行函数
function Disable-WindowsUpdate {
    Write-Host "`n[1] 正在下载禁用 Windows 更新..." -ForegroundColor Green
    try {
        irm https://cdn.jsdmirror.com/gh/huibsoft/static/wub.ps1 | iex
        Write-Host "? Windows 更新已禁用" -ForegroundColor Green
    } catch {
        Write-Host "? 执行失败: $_" -ForegroundColor Red
    }
}

function Disable-SecurityCenter {
    Write-Host "`n[2] 正在下载禁用 Windows 安全中心..." -ForegroundColor Green
    try {
        irm https://cdn.jsdmirror.com/gh/huibsoft/static/dControl.ps1 | iex
        Write-Host "? 安全中心已禁用" -ForegroundColor Green
    } catch {
        Write-Host "? 执行失败: $_" -ForegroundColor Red
    }
}

function Restore-ClassicMenu {
    Write-Host "`n[3] 正在下载恢复经典右键菜单..." -ForegroundColor Green
    try {
        irm https://cdn.jsdmirror.com/gh/huibsoft/static/W11ClassicMenu.ps1 | iex
        Write-Host "? 经典右键菜单已恢复" -ForegroundColor Green
    } catch {
        Write-Host "? 执行失败: $_" -ForegroundColor Red
    }
}

function Activate-Windows {
    Write-Host "`n[4] 正在下载激活 Windows..." -ForegroundColor Green
    try {
        irm https://cdn.jsdmirror.com/gh/huibsoft/static/KMS_v64.ps1 | iex
        Write-Host "? 激活命令已执行，请查看上方输出" -ForegroundColor Green
    } catch {
        Write-Host "? 执行失败: $_" -ForegroundColor Red
    }
}

function Clear-Memory {
    Write-Host "`n[5] 正在清理内存..." -ForegroundColor Green
    try {
        irm https://cdn.jsdmirror.com/gh/huibsoft/static/ReduceMemory.ps1 | iex
        Write-Host "? 内存清理完成" -ForegroundColor Green
    } catch {
        Write-Host "? 执行失败: $_" -ForegroundColor Red
    }
}

# 主菜单循环
do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      Windows 优化工具箱 v1.0" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 禁用 Windows 更新" -ForegroundColor Yellow
    Write-Host "  [2] 禁用 Windows 安全中心" -ForegroundColor Yellow
    Write-Host "  [3] 恢复经典右键菜单 (Win11)" -ForegroundColor Yellow
    Write-Host "  [4] 激活 Windows (KMS)" -ForegroundColor Yellow
    Write-Host "  [5] 内存清理工具" -ForegroundColor Yellow
    Write-Host "  [0] 退出" -ForegroundColor Red
    Write-Host ""
    Write-Host "提示：部分操作可能需要重启生效" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "请输入数字选择"

    switch ($choice) {
        "1" { Disable-WindowsUpdate }
        "2" { Disable-SecurityCenter }
        "3" { Restore-ClassicMenu }
        "4" { Activate-Windows }
        "5" { Clear-Memory }
        "0" {
            Write-Host "`n已退出" -ForegroundColor Gray
            exit
        }
        default {
            Write-Host "`n无效选择，请重新输入" -ForegroundColor Red
            Start-Sleep -Seconds 1
            continue
        }
    }

    Write-Host "`n"
    Read-Host "按 Enter 键返回菜单"
} while ($true)