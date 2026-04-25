# 需要以管理员身份运行此脚本
# 保存为 .ps1 文件，右键点击选择“使用 PowerShell 运行”

# 严格模式，帮助捕获潜在错误
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 配置参数
$zipUrl = "https://cdn.jsdmirror.com/gh/huibsoft/static/HEU_KMS_Activator_v63.3.4.zip"
$targetDir = Join-Path $HOME 'KMS'
$zipFileName = "HEU_KMS_Activator_v63.3.4.zip"
$zipPath = Join-Path $targetDir $zipFileName

# 函数：输出带时间戳的信息
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# 函数：等待用户按任意键退出
function Wait-ForKeyPress {
    Write-Host "`nPress any key to exit..." -ForegroundColor Green
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $PSCommandPath + "`""
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
    } catch {
        throw "Failed to elevate to Administrator: $_"
    }
    exit 0
}

Write-Host ""
Write-Host "HEU KMS Activator" -ForegroundColor Cyan
Write-Host ""

# 准备目标目录
if (Test-Path $targetDir) {
    Remove-Item $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

$success = $false
try {
    # 添加 Windows Defender 排除项（允许失败，不影响主流程）
    try {
        Add-MpPreference -ExclusionPath $targetDir -ErrorAction Stop
        Add-MpPreference -ExclusionPath (Join-Path $env:TEMP '_temp_heu168yyds') -ErrorAction Stop
    } catch {
        Write-Log "Warning: Failed to add Defender exclusions: $($_.Exception.Message)" -Color Yellow
    }

    # 下载 zip 文件
    Write-Log "Downloading file..." -Color Yellow
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    } catch {
        throw "Download failed: $_"
    }

    # 解压 zip 文件
    Write-Log "Extracting archive..." -Color Yellow
    try {
        Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
    } catch {
        throw "Extraction failed: $($_.Exception.Message)"
    }

    # 查找 exe 文件
    $controlFiles = @(Get-ChildItem -Path $targetDir -Filter *.exe -Recurse)
    if ($controlFiles.Count -eq 0) {
        throw "No executable file found to run"
    }

    # 运行 KMS 激活工具
    $exePath = $controlFiles[0].FullName
    Write-Log "Running: $exePath" -Color Green
    try {
        Start-Process -FilePath $exePath -WorkingDirectory $targetDir -Wait -NoNewWindow
        # 可选：激活完成后删除 exe 文件（若不需要保留）
        if (Test-Path $exePath) {
            Remove-Item $exePath -Force -ErrorAction SilentlyContinue
        }
    } catch {
        throw "Failed to run: $_"
    }

    $success = $true
} catch {
    Write-Log "An error occurred during installation:" -Color Red
    Write-Host "    $_" -ForegroundColor Red
    Wait-ForKeyPress
    exit 1
} finally {
    # 清理 zip 文件（保留解压出的文件）
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }
}

if ($success) {
    Write-Log "Activation completed successfully." -Color Green
    #Wait-ForKeyPress
    exit 0
}