# 首次发布到 GitHub：初始化仓库 → 提交 → 推送。
# 用法：右键本文件 → 使用 PowerShell 运行
#
# 前提（只做一次）：
#   1. https://github.com/new 建一个名为 dsh-paper-download 的空仓库（Public，不要勾 README）
#   2. 第一次推送时浏览器会弹出授权，登录 GitHub 点 Authorize 即可
$ErrorActionPreference = 'Stop'
$user  = 'Usagi826'
$repo  = 'dsh-paper-download'
$email = 'cxzhujunqs@163.com'
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($text) { Write-Host "`n==> $text" -ForegroundColor Cyan }
function Fail($text) {
  Write-Host "`n[失败] $text" -ForegroundColor Red
  Read-Host "按回车关闭窗口"
  exit 1
}

Set-Location $here

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "找不到 git，请先安装 Git for Windows" }

Step "1/6 设置 git 身份"
$name = git config --global user.name
$mail = git config --global user.email
if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($mail)) {
  git config --global user.name $user
  git config --global user.email $email
  Write-Host "已设置 user.name=$user  user.email=$email"
} else {
  Write-Host "已有身份：$name [$mail]"
}
if ([string]::IsNullOrWhiteSpace((git config --global credential.helper))) {
  git config --global credential.helper manager
  Write-Host "已启用 Windows 凭据记忆（推送只需登录一次）"
}

Step "2/6 去掉会改写 GitHub 地址的旧配置"
foreach ($key in @(
  'url.https://github.com/.insteadof',
  'url.https://gitclone.com/github.com/.insteadof',
  'url.https://hub.fastgit.org/github.com/.insteadof'
)) {
  $null = git config --global --unset-all $key 2>$null
}
Write-Host "完成"

Step "3/6 初始化仓库"
if (Test-Path ".git") {
  Write-Host "已经是 git 仓库，跳过初始化"
} else {
  $null = git init -b main
  Write-Host "已初始化"
}

Step "4/6 提交文件"
git add .
$pending = git status --porcelain
if ([string]::IsNullOrWhiteSpace($pending)) {
  Write-Host "没有新改动需要提交"
} else {
  $null = git commit -m "feat: 文献下载插件 v1.0.0"
  if ($LASTEXITCODE -ne 0) { Fail "提交失败，请把上面的红字发给我" }
  Write-Host "已提交"
}

Step "5/6 设置远程地址"
$url = "https://github.com/$user/$repo.git"
$hasOrigin = git remote | Select-String -SimpleMatch 'origin'
if ($hasOrigin) { $null = git remote set-url origin $url } else { $null = git remote add origin $url }
Write-Host "origin = $url"

Step "6/6 推送（第一次会弹出浏览器让登录 GitHub，点 Authorize）"
git push -u origin main
if ($LASTEXITCODE -ne 0) { Fail "推送失败。常见原因：仓库名不对或未在 GitHub 建仓库；网络问题可重试" }

Write-Host "`n完成！仓库地址：https://github.com/$user/$repo" -ForegroundColor Green
Write-Host "别人在 DeepSeek Harness「插件 → 添加插件」里粘贴这个地址即可安装。"
Read-Host "按回车关闭窗口"
