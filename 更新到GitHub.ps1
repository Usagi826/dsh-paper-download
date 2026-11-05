# 之后修改了插件代码，用这个把改动推到 GitHub。
# 用法：右键本文件 → 使用 PowerShell 运行
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Fail($text) {
  Write-Host "`n[失败] $text" -ForegroundColor Red
  Read-Host "按回车关闭窗口"
  exit 1
}

Set-Location $here

$message = Read-Host "这次改了什么？（直接回车用默认说明）"
if ([string]::IsNullOrWhiteSpace($message)) { $message = "更新文献下载插件" }

git add .
$pending = git status --porcelain
if ([string]::IsNullOrWhiteSpace($pending)) {
  Write-Host "没有改动，无需推送" -ForegroundColor Yellow
  Read-Host "按回车关闭窗口"
  exit 0
}

$null = git commit -m $message
if ($LASTEXITCODE -ne 0) { Fail "提交失败，请把上面的红字发给我" }

git push
if ($LASTEXITCODE -ne 0) { Fail "推送失败，检查网络后重试" }

Write-Host "`n已推送成功。" -ForegroundColor Green
Read-Host "按回车关闭窗口"
