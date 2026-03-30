<#
.SYNOPSIS
    Git自动提交和推送脚本
.DESCRIPTION
    自动添加所有更改、提交并推送到当前分支
.PARAMETER Message
    自定义提交消息（可选）
#>

param(
    [string]$Message
)

# 颜色输出函数
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -NoNewline
}

# 显示当前目录（紫色）
Write-Host "Current git project: " -NoNewline
Write-Host "$(Get-Location)" -ForegroundColor Magenta
Write-Host ""

# 检查是否为git仓库
if (-not (Test-Path ".git")) {
    Write-Host "This directory has not been initialized with git!" -ForegroundColor Red
    exit 1
}

# 获取当前分支
$branchLine = git branch | Where-Object { $_ -like "* *" }
$branch = $branchLine.TrimStart('*').Trim()

# 显示分支信息（绿色）
Write-Host "Auto commit and push to branch: " -NoNewline
Write-Host "[$branch]" -ForegroundColor Green
Write-Host ""

# 添加所有更改
git add .

# 获取git配置的用户名
$name = git config user.name

# 设置提交消息
if ([string]::IsNullOrEmpty($Message)) {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = "auto commit and push by $name on $date"
} else {
    $msg = $Message
}

# 提交更改
git commit -m $msg

# 推送到远程仓库
git push -u origin $branch

# 显示完成状态
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Auto commit and push completed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Auto commit and push failed!" -ForegroundColor Red
}