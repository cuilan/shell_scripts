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
# git add .