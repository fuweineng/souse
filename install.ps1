# souse 一键安装（Windows）
#
#   一行安装：
#     irm https://souse.neng.page/install.ps1 | iex
#
#   常用参数：
#     & ([scriptblock]::Create((irm https://souse.neng.page/install.ps1))) -Port 8080
#     irm ... | iex; Uninstall-Souse        # 卸载（保留数据）
#
# 对标 magpie 的部分：一行装完 → 自动建配置 → 注册开机自启 → 起服务 → 打印访问地址与初始密码。
# 三个访问层级：
#   本机   http://127.0.0.1:<port>       房东自己用
#   局域网 http://<内网IP>:<port>        同一 WiFi 的手机 / 住户扫码就能用
#   公网   需要隧道（安装后 `souse.cmd tunnel` 或看下载页说明）
[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\souse",
    [int]$Port = 8080,
    [string]$Channel = "stable",
    [switch]$NoAutostart,
    [switch]$Update,
    [switch]$Uninstall,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Repo = "fuweineng/souse"
$ExeName = "610souse.exe"
$TaskName = "souse"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Write-Warn2($m) { Write-Host "  !   $m" -ForegroundColor Yellow }
function Write-Err($m)  { Write-Host "  X   $m" -ForegroundColor Red }

function Get-Arch {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { return "amd64" }
        "ARM64" { return "arm64" }
        default { throw "不支持的架构: $env:PROCESSOR_ARCHITECTURE" }
    }
}

function Test-PortFree([int]$p) {
    try {
        $l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $p)
        $l.Start(); $l.Stop(); return $true
    } catch { return $false }
}

function Get-FreePort([int]$start) {
    for ($p = $start; $p -lt $start + 20; $p++) { if (Test-PortFree $p) { return $p } }
    throw "找不到可用端口（$start 起 20 个都被占用）"
}

function Get-LatestRelease {
    $api = "https://api.github.com/repos/$Repo/releases/latest"
    $r = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "souse-installer" } -TimeoutSec 30
    return $r
}

function Save-FileWithMirrors([string]$Url, [string]$Dest, [int]$TimeoutSec = 90) {
    $mirrors = @("https://gh-proxy.com/", "https://ghfast.top/", "https://ghproxy.net/")
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Dest -TimeoutSec $TimeoutSec -UseBasicParsing
        return $true
    } catch {
        Write-Warn2 "直连失败/超时，改用镜像"
    }
    foreach ($m in $mirrors) {
        try {
            Write-Step "镜像 $m"
            Invoke-WebRequest -Uri "$m$Url" -OutFile $Dest -TimeoutSec 900 -UseBasicParsing
            return $true
        } catch { Write-Warn2 "镜像不通: $m" }
    }
    return $false
}

function New-Config([string]$dir, [int]$port) {
    # 注意：发行包自带一份 config.yaml（secret 为空、端口 8080），不能当作用户配置沿用。
    # 判定方式看标记行：有 # managed-by: souse-installer 才是我们生成的（可能被用户改过，保留）。
    $cfg = Join-Path $dir "config.yaml"
    $marker = "# managed-by: souse-installer"
    $secret = -join ((48..57) + (97..102) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

    if (Test-Path $cfg) {
        $txt = Get-Content $cfg -Raw -Encoding UTF8
        if ($txt -match [regex]::Escape($marker)) {
            Write-Ok "沿用已有配置（安装器生成过，可能已手工改过）"
            return
        }
        Copy-Item $cfg "$cfg.shipped" -Force
        Write-Warn2 "检测到发行包自带 config.yaml（secret 为空），已备份为 config.yaml.shipped"
    } else {
        $tpl = Join-Path $dir "config.yaml.example"
        if (Test-Path $tpl) { $txt = Get-Content $tpl -Raw -Encoding UTF8 } else { $txt = "" }
    }

    if (-not $txt -or $txt.Trim().Length -lt 20) {
        $txt = @"
server:
    rest_port: $port
    mcp_path: /mcp/sse
    static_dir: ./web/static
database:
    driver: sqlite
    dsn: data/db/souse.db
jwt:
    secret: "$secret"
    expiresecs: 86400
    accessexpiresecs: 900
"@
    } else {
        $txt = $txt -replace '(?m)^(\s*rest_port:\s*)\d+', "`${1}$port"
        # 把空的 jwt.secret 填成随机值（发行默认空串，所有安装会共用同一份，必须换）。
        # 逐行处理保留缩进；只认第一处「secret: 空值」，app_secret 不动。
        $lines = $txt -split "`r?`n"
        $empties = @('', "''", '""')
        for ($k = 0; $k -lt $lines.Count; $k++) {
            $t = $lines[$k].Trim()
            if ($t -match '^secret:\s*(.*)$') {
                $val = $Matches[1].Trim()
                if ($empties -contains $val) {
                    $indent = $lines[$k].Substring(0, $lines[$k].Length - $lines[$k].TrimStart().Length)
                    $lines[$k] = $indent + 'secret: "' + $secret + '"'
                    break
                }
            }
        }
        $txt = ($lines -join "`r`n")
    }
    $txt = $marker + "`r`n" + $txt
    Set-Content -Path $cfg -Value $txt -Encoding UTF8
    Write-Ok "已生成配置 $cfg（端口 $port，JWT 随机）"
}

function New-Launcher([string]$dir) {
    # 启动器：固定工作目录（配置与 data/ 都是相对路径），隐藏窗口
    $cmd = Join-Path $dir "souse.cmd"
    @"
@echo off
cd /d "%~dp0"
if not exist "logs" mkdir "logs"
start "" /min cmd /c ""%~dp0$ExeName" "%~dp0config.yaml" >> "%~dp0logs\souse.log" 2>&1"
"@ | Set-Content -Path $cmd -Encoding ASCII
    Write-Ok "启动器 $cmd"
}

function Register-Autostart([string]$dir) {
    if ($NoAutostart) { Write-Warn2 "按要求跳过开机自启"; return }
    $cmd = Join-Path $dir "souse.cmd"
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$cmd`"" -WorkingDirectory $dir
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-Ok "已注册登录自启（计划任务 $TaskName）"
}

function Stop-Souse {
    Get-Process -Name "610souse" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 800
}

function Start-Souse([string]$dir, [int]$port) {
    Stop-Souse
    $exe = Join-Path $dir $ExeName
    $logDir = Join-Path $dir "logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir "souse.log"
    Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c", "`"`"$exe`" `"$(Join-Path $dir 'config.yaml')`" >> `"$logFile`" 2>&1`"" `
        -WorkingDirectory $dir -WindowStyle Hidden
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 500
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:$port/" -TimeoutSec 2 -UseBasicParsing
            if ($r.StatusCode -ge 200) { Write-Ok "服务已起来（HTTP $($r.StatusCode)）"; return $true }
        } catch { }
    }
    Write-Warn2 "服务未在 20 秒内响应，看 $dir\logs\"
    return $false
}

function Show-Result([string]$dir, [int]$port) {
    $lan = $null
    try {
        $idx = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop |
                Sort-Object RouteMetric | Select-Object -First 1).InterfaceIndex
        $lan = (Get-NetIPAddress -InterfaceIndex $idx -AddressFamily IPv4 -ErrorAction Stop).IPAddress
    } catch {
        $lan = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -notlike "172.1*" } |
                Select-Object -First 1).IPAddress
    }
    Write-Host ""
    Write-Host "  本机访问： http://127.0.0.1:$port" -ForegroundColor Green
    if ($lan) { Write-Host "  局域网  ： http://$($lan):$port   （同一 WiFi 的手机/住户可用）" -ForegroundColor Green }
    Write-Host "  安装目录： $dir"
    Write-Host "  配置    ： $dir\config.yaml"
    Write-Host ""
    $log = Join-Path $dir "logs"
    $logFile = Join-Path $log "souse.log"
    if (Test-Path $logFile) {
        $u = Select-String -Path $logFile -Pattern 'Username:\s*([^"\s]+)' | Select-Object -Last 1
        $p = Select-String -Path $logFile -Pattern 'Password:\s*([^"\s]+)' | Select-Object -Last 1
        if ($u) { Write-Host "  用户名  ： $($u.Matches[0].Groups[1].Value)" -ForegroundColor Yellow }
        if ($p) { Write-Host "  初始密码： $($p.Matches[0].Groups[1].Value)" -ForegroundColor Yellow }
        Write-Host "  （只显示一次；日志在 $logFile）" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  公网访问：装好后运行  $dir\souse.cmd tunnel  跟着提示开通" -ForegroundColor Cyan
    Write-Host ""
}

# ─────────────────────────── 卸载 ───────────────────────────
if ($Uninstall) {
    Write-Step "卸载 souse（保留 $InstallDir\data 与 config.yaml）"
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Stop-Souse
    Write-Ok "已停止服务并移除自启。程序目录未删：$InstallDir"
    exit 0
}

# ─────────────────────────── 安装 / 更新 ───────────────────────────
Write-Step "souse 安装器（Windows / $(Get-Arch)）"

$arch = Get-Arch
$assetName = "souse-windows-$arch.zip"

Write-Step "查询最新版本"
$rel = Get-LatestRelease
$version = $rel.tag_name
if (-not $version) { Write-Err "取不到版本号（检查网络）"; exit 1 }
Write-Ok "最新版本 $version"

if ($Update -and (Test-Path (Join-Path $InstallDir "VERSION"))) {
    $cur = (Get-Content (Join-Path $InstallDir "VERSION") -Raw).Trim()
    if ($cur -eq $version) { Write-Ok "已是最新 $version"; exit 0 }
    Write-Step "升级 $cur → $version"
}

$asset = $rel.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
if (-not $asset) { Write-Err "Release 里没有 $assetName"; exit 1 }
$sumAsset = $rel.assets | Where-Object { $_.name -eq "$assetName.sha256" } | Select-Object -First 1

$tmp = Join-Path $env:TEMP ("souse-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp $assetName

Write-Step "下载 $assetName（$([math]::Round($asset.size/1MB,1)) MB）"
if ($DryRun) { Write-Ok "dry-run：跳过下载"; exit 0 }
if (-not (Save-FileWithMirrors $asset.browser_download_url $zip)) {
    Write-Err "下载失败（直连与镜像都不通）"; exit 1
}

# SHA256 校验：有校验文件就必须过，否则拒绝安装
if ($sumAsset) {
    $sumFile = Join-Path $tmp "sum.txt"
    if (Save-FileWithMirrors $sumAsset.browser_download_url $sumFile) {
        $want = ((Get-Content $sumFile -Raw).Trim() -split '\s+')[0].ToLower()
        $got = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        if ($want -ne $got) { Write-Err "SHA256 不匹配（期望 $want，实际 $got）→ 拒绝安装"; exit 1 }
        Write-Ok "SHA256 校验通过"
    } else {
        Write-Warn2 "取不到 .sha256，跳过校验（不推荐）"
    }
}

if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
Write-Step "解压到 $InstallDir"
Expand-Archive -Path $zip -DestinationPath $tmp -Force
$inner = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "souse-windows-*" } | Select-Object -First 1
if (-not $inner) { Write-Err "压缩包结构异常（找不到 souse-windows-*）"; exit 1 }
Stop-Souse
# 覆盖安装时不能把用户的 config.yaml 和 data/ 冲掉（发行包自带一份 config.yaml，
# 无脑 Copy-Item * 会让每次重装都换成默认配置、连 JWT secret 都重置）。
Get-ChildItem $inner.FullName -Force |
    Where-Object { $_.Name -notin @('config.yaml', 'data', 'logs') } |
    ForEach-Object { Copy-Item $_.FullName -Destination $InstallDir -Recurse -Force }
Set-Content -Path (Join-Path $InstallDir "VERSION") -Value $version -Encoding ASCII
Write-Ok "已解压到 $InstallDir"

New-Config $InstallDir $Port
New-Launcher $InstallDir
Register-Autostart $InstallDir

$port = (Select-String -Path (Join-Path $InstallDir "config.yaml") -Pattern "rest_port:\s*(\d+)").Matches.Groups[1].Value
if (-not $port) { $port = $Port }

Write-Step "启动服务"
if (Start-Souse $InstallDir ([int]$port)) { Show-Result $InstallDir ([int]$port) }
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
