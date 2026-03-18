# 需要以管理员身份运行此脚本
# 保存为 .ps1 文件，右键点击选择“使用 PowerShell 运行”

# 严格模式，帮助捕获潜在错误
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 配置参数
$cabUrl = "https://cdn.jsdmirror.com/gh/huibsoft/static/AxSafeControls.cab"
$targetDir = "C:\ICBC"
$cabFileName = "AxSafeControls.cab"
$cabPath = Join-Path $targetDir $cabFileName

# 函数：输出带时间戳的信息
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# 函数：等待用户按任意键退出
function Wait-ForKeyPress {
    Write-Host "`n请按任意键退出..." -ForegroundColor Green
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "错误：请以管理员身份运行此脚本！" -ForegroundColor Red
    Wait-ForKeyPress
    exit 1
}

Write-Host ""
Write-Host "工行网银验证码控件" -ForegroundColor Cyan
Write-Host ""

# 1. 准备目标目录
if (Test-Path $targetDir) {
    Remove-Item $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

# 2. 添加 Defender 排除项（忽略已存在时的错误）
Add-MpPreference -ExclusionPath $targetDir -ErrorAction SilentlyContinue

try {
    # 3. 下载 CAB 文件
    Write-Log "正在下载控件..." -Color Yellow
    try {
        Invoke-WebRequest -Uri $cabUrl -OutFile $cabPath -UseBasicParsing
    } catch {
        throw "下载失败: $_"
    }

    # 4. 解压 CAB 文件
    Write-Log "正在解压文件..." -Color Yellow
    $expandOutput = & expand $cabPath -F:* $targetDir 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "解压失败: $expandOutput"
    }

    # 5. 查找所有需要注册的 DLL 文件
    $controlFiles = Get-ChildItem -Path $targetDir -Include *.dll -Recurse
    if ($controlFiles.Count -eq 0) {
        throw "在解压文件中未找到任何需要注册的控件文件（.dll）。"
    }

    Write-Log "找到 $($controlFiles.Count) 个待注册文件：" -Color Cyan
    $controlFiles | ForEach-Object { Write-Host "    - $($_.Name)" }

    # 6. 确定要使用的 regsvr32 路径（优先使用 32 位版本）
    $regsvr32 = if (Test-Path "$env:SystemRoot\SysWOW64\regsvr32.exe") {
        "$env:SystemRoot\SysWOW64\regsvr32.exe"
    } else {
        "$env:SystemRoot\System32\regsvr32.exe"
    }

    # 7. 循环注册每个控件文件（仅显示每个文件的注册结果）
    Write-Log "开始注册控件..." -Color Yellow

    foreach ($file in $controlFiles) {
        Write-Host "正在注册: $($file.Name) ... " -NoNewline
        try {
            $regResult = Start-Process -FilePath $regsvr32 -ArgumentList "/s `"$($file.FullName)`"" -Wait -PassThru -NoNewWindow
            if ($regResult.ExitCode -eq 0) {
                Write-Host "成功" -ForegroundColor Green
            } else {
                Write-Host "失败 (错误码: $($regResult.ExitCode))" -ForegroundColor Red
            }
        } catch {
            Write-Host "异常: $_" -ForegroundColor Red
        }
    }

} catch {
    Write-Log "安装过程中发生错误：" -Color Red
    Write-Host "    $_" -ForegroundColor Red
    Wait-ForKeyPress
    exit 1
} finally {
    # 8. 清理 CAB 文件（保留解压出的文件）
    if (Test-Path $cabPath) {
        Remove-Item $cabPath -Force -ErrorAction SilentlyContinue
    }
	Write-Log "控件安装完成 => $targetDir" -Color Yellow
}

# 成功完成，等待按键退出
Wait-ForKeyPress
exit 0