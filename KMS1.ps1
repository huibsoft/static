# 需要以管理员身份运行此脚本
# 保存为 .ps1 文件，右键点击选择“使用 PowerShell 运行”

# 严格模式，帮助捕获潜在错误
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 配置参数
$cabUrl = "https://cdn.jsdmirror.com/gh/huibsoft/static/HEU_KMS_Activator_v63.3.4.zip"
$targetDir = "C:\KMS"
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
    Write-Host "`n请按任意键退出..." -ForegroundColor Green
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    #Write-Host "错误：请以管理员身份运行此脚本！" -ForegroundColor Red
    #Wait-ForKeyPress
    #exit 1
    # 不是管理员：重新启动脚本并请求提权
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $PSCommandPath + "`""
    Start-Process PowerShell -Verb RunAs -ArgumentList $arguments

	Wait-ForKeyPress
	exit 1
}

Write-Host ""
Write-Host "Windows KMS 激活工具" -ForegroundColor Cyan
Write-Host ""

# 1. 准备目标目录
if (Test-Path $targetDir) {
    Remove-Item $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

Add-MpPreference -ExclusionPath $targetDir -ErrorAction Stop
Add-MpPreference -ExclusionPath (Join-Path $env:TEMP '_temp_heu168yyds') -ErrorAction Stop

try {
	# 3. 下载 zip 文件
	Write-Log "正在下载文件..." -Color Yellow
	try {
		Invoke-WebRequest -Uri $cabUrl -OutFile $zipPath -UseBasicParsing
	} catch {
		throw "下载失败: $_"
	}

	# 4. 解压 zip 文件
	Write-Log "正在解压文件..." -Color Yellow
	try {
		Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
	} catch {
		throw "解压失败: $($_.Exception.Message)"
	}

	# 5. 查找 exe 文件（确保结果为数组）
	$controlFiles = @(Get-ChildItem -Path $targetDir -Filter *.exe -Recurse)
	if ($controlFiles.Count -eq 0) {
		throw "找不到要运行的可执行文件"
	}

	# 6. 运行KMS激活工具
	$exePath = $controlFiles[0].FullName
	Write-Log "正在运行: $exePath" -Color Green
	try {
		Start-Process -FilePath $exePath -WorkingDirectory $targetDir -NoNewWindow
	} catch {
		throw "运行失败: $_"
	}
	exit 0
} catch {
    Write-Log "安装过程中发生错误：" -Color Red
    Write-Host "    $_" -ForegroundColor Red
    Wait-ForKeyPress
    exit 1
} finally {
    # 7. 清理 zip 文件（保留解压出的文件）
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }
}

# 成功完成，等待按键退出
Wait-ForKeyPress
exit 0
