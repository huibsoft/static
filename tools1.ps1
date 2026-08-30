# 1. 定义 URL 和临时文件路径
$url = "https://cdn.jsdmirror.com/gh/huibsoft/static/tools_1.ps1"
$tempFile = "$env:TEMP\tools_1.ps1"

# 2. 下载文件（保持原始字节不变）
Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing

# 3. 关键步骤：强制以 UTF-8 编码读取文件内容
$content = Get-Content -Path $tempFile -Raw -Encoding UTF8

# 4. 执行脚本
Invoke-Expression $content

# 5. 清理临时文件（可选）
Remove-Item $tempFile -Force