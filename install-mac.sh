#!/bin/sh
# souse 一键安装（macOS，含 Apple Silicon / Intel）
#
#   curl -fsSL https://souse.dpxon.com/install-mac.sh | sh
#
# 与 Linux 版的差别（都是平台特性逼出来的）：
#   · 不写系统目录、不需要 sudo：装到 ~/Library/Application Support/souse
#   · 服务用 launchd（LaunchAgent，登录即启动、崩溃自动重启），不用 systemd
#   · 未签名二进制会被 Gatekeeper 拦：装完自动 xattr 去掉隔离属性
#   · 运行日志同时落 logs/souse.log，初始密码从这里取
#
# 可覆盖的环境变量：
#   SOUSE_DIR=/自定义/安装目录   SOUSE_PORT=8080   SOUSE_VERSION=v1.0.1
#   SOUSE_MIRROR=https://gh-proxy.com/   SOUSE_NO_START=1
set -eu

REPO="fuweineng/souse"
APP_NAME="souse"
PORT="${SOUSE_PORT:-8080}"

C_RED=$(printf '\033[31m'); C_GRN=$(printf '\033[32m')
C_YEL=$(printf '\033[33m'); C_BLU=$(printf '\033[36m'); C_RST=$(printf '\033[0m')
info() { printf '%s[INFO]%s %s\n' "$C_BLU" "$C_RST" "$*"; }
ok()   { printf '%s[OK]%s %s\n'   "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$C_YEL" "$C_RST" "$*"; }
die()  { printf '%s[ERR]%s %s\n'  "$C_RED" "$C_RST" "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "这是 macOS 安装脚本；Linux 用 install.sh，Windows 用 install.ps1"

case "$(uname -m)" in
  arm64) ARCH=arm64 ;;
  x86_64) ARCH=amd64 ;;
  *) die "不支持的架构: $(uname -m)" ;;
esac

APP_DIR="${SOUSE_DIR:-$HOME/Library/Application Support/$APP_NAME}"
BIN_NAME="610souse"
PLIST="$HOME/Library/LaunchAgents/page.neng.souse.plist"
LABEL="page.neng.souse"
LOG_DIR="$APP_DIR/logs"
LOG_FILE="$LOG_DIR/souse.log"
MARKER="# managed-by: souse-installer"

mkdir -p "$APP_DIR" "$LOG_DIR"

# ── 取版本 ──────────────────────────────────────────────
latest_version() {
  if [ -n "${SOUSE_VERSION:-}" ]; then printf '%s' "$SOUSE_VERSION"; return 0; fi
  _j=$(curl -fsSL --max-time 30 "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null || true)
  [ -n "$_j" ] || return 1
  printf '%s' "$_j" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1
}

# ── 下载（直连 60s，失败换镜像；任何来源都要过 SHA256）────────
fetch() {
  _url="$1"; _dest="$2"; _t="${3:-60}"
  curl -fL --connect-timeout 15 --max-time "$_t" -o "$_dest" "$_url" 2>/dev/null
}

VERSION=$(latest_version) || die "取不到最新版本（GitHub API 不通）"
[ -n "$VERSION" ] || die "GitHub 没有返回版本号"
info "macOS 安装器 · $ARCH · 版本 $VERSION"

ASSET="souse-darwin-${ARCH}.tar.gz"
BASE="https://github.com/$REPO/releases/download/$VERSION"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/souse.XXXXXX")
trap 'rm -rf "$TMP"' EXIT INT TERM

DEST="$TMP/$ASSET"
GOT=0
MIRRORS="${SOUSE_MIRROR:-https://gh-proxy.com/,https://ghfast.top/,https://ghproxy.net/}"

info "下载 $ASSET ..."
if fetch "$BASE/$ASSET" "$DEST" 60; then GOT=1; else warn "直连 60 秒未完成，改用镜像"; fi

if [ "$GOT" != "1" ]; then
  OLDIFS=$IFS; IFS=','
  for m in $MIRRORS; do
    IFS=$OLDIFS
    [ -n "$m" ] || continue
    info "镜像 $m"
    if fetch "${m}${BASE}/${ASSET}" "$DEST" 1800; then GOT=1; ok "镜像下载成功"; break; fi
  done
  IFS=$OLDIFS
fi
[ "$GOT" = "1" ] || die "下载失败（直连与镜像都不通）"

# ── 校验 ────────────────────────────────────────────────
# 校验文件也走镜像：GitHub 直连超时时，checksum 一起失败就没法验证（踩过）
SUM_OK=0
if fetch "$BASE/$ASSET.sha256" "$TMP/sum" 60; then SUM_OK=1; fi
if [ "$SUM_OK" != "1" ]; then
  OLDIFS=$IFS; IFS=','
  for m in ${SOUSE_MIRROR:-https://gh-proxy.com/,https://ghfast.top/,https://ghproxy.net/}; do
    IFS=$OLDIFS
    [ -n "$m" ] || continue
    if fetch "${m}${BASE}/${ASSET}.sha256" "$TMP/sum" 120; then SUM_OK=1; break; fi
  done
  IFS=$OLDIFS
fi

if [ "$SUM_OK" = "1" ]; then
  WANT=$(awk '{print $1}' "$TMP/sum" | head -1 | tr 'A-F' 'a-f')
  GOTSUM=$(shasum -a 256 "$DEST" | awk '{print $1}' | tr 'A-F' 'a-f')
  [ "$WANT" = "$GOTSUM" ] || die "SHA256 不匹配（期望 ${WANT}，实际 ${GOTSUM}）→ 拒绝安装"
  ok "SHA256 校验通过"
else
  warn "取不到 .sha256，跳过校验（不推荐）"
fi

# ── 解包（保留用户的 config.yaml / data / logs）──────────────
info "解包到 $APP_DIR"
tar xzf "$DEST" -C "$TMP"
SRC=$(find "$TMP" -maxdepth 1 -type d -name "souse-darwin-*" | head -1)
[ -n "$SRC" ] || die "压缩包结构异常（找不到 souse-darwin-* 目录）"

# 停掉正在跑的实例，避免替换二进制时 busy
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
pkill -f "$APP_DIR/$BIN_NAME" >/dev/null 2>&1 || true
sleep 1

for item in "$SRC"/*; do
  base=$(basename "$item")
  case "$base" in
    config.yaml|data|logs) continue ;;   # 用户数据一律不覆盖
  esac
  rm -rf "$APP_DIR/$base"
  cp -R "$item" "$APP_DIR/$base"
done
printf '%s\n' "$VERSION" > "$APP_DIR/VERSION"
chmod +x "$APP_DIR/$BIN_NAME" 2>/dev/null || true
# 未签名二进制：去掉隔离属性，否则首次运行会被 Gatekeeper 直接杀掉
xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true
ok "程序已就位（${APP_DIR}/${BIN_NAME}）"

# ── 配置 ────────────────────────────────────────────────
gen_config() {
  cfg="$APP_DIR/config.yaml"
  secret=$(openssl rand -hex 16 2>/dev/null || od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
  if [ -f "$cfg" ] && grep -qF "$MARKER" "$cfg" 2>/dev/null; then
    ok "沿用已有配置 $cfg"
    return 0
  fi
  if [ -f "$cfg" ]; then
    cp "$cfg" "$cfg.shipped"
    warn "检测到发行包自带 config.yaml（secret 为空），已备份为 config.yaml.shipped"
    src="$cfg.shipped"
  else
    src="$APP_DIR/config.yaml.example"
    [ -f "$src" ] || src=""
  fi

  if [ -n "$src" ] && [ -f "$src" ]; then
    # 端口按参数改；只填第一处空 secret（jwt.secret），app_secret 等保持原样。
    # 这里不用 awk 拼正则：引号嵌套在 sh/dash/BSD awk 上极易出错（踩过一次），
    # 改成逐行读 + case 判断，可读且可移植。
    : > "$cfg"
    filled=0
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        *secret:*)
          val=$(printf '%s' "${line#*secret:}" | tr -d " '\"\t")
          if [ -z "$val" ] && [ "$filled" = "0" ]; then
            printf '%ssecret: "%s"\n' "${line%%secret:*}" "$secret" >> "$cfg"
            filled=1
          else
            printf '%s\n' "$line" >> "$cfg"
          fi
          ;;
        *rest_port:*)
          printf '%s\n' "$line" | sed 's/[0-9][0-9]*$/'"$PORT"'/' >> "$cfg"
          ;;
        *)
          printf '%s\n' "$line" >> "$cfg"
          ;;
      esac
    done < "$src"
  else
    cat > "$cfg" <<EOF
server:
    rest_port: $PORT
    mcp_path: /mcp/sse
    static_dir: ./web/static
database:
    driver: sqlite
    dsn: data/db/souse.db
jwt:
    secret: "$secret"
    expiresecs: 86400
    accessexpiresecs: 900
EOF
  fi
  { printf '%s\n' "$MARKER"; cat "$cfg"; } > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  ok "已生成配置 ${cfg}（端口 ${PORT}，JWT 随机）"
}
gen_config

# ── launchd 服务 ────────────────────────────────────────
write_agent() {
  mkdir -p "$(dirname "$PLIST")"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$APP_DIR/$BIN_NAME</string>
    <string>$APP_DIR/config.yaml</string>
  </array>
  <key>WorkingDirectory</key><string>$APP_DIR</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$LOG_FILE</string>
  <key>StandardErrorPath</key><string>$LOG_FILE</string>
  <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST" || die "launchd 注册失败（${PLIST}）"
  launchctl enable "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
  ok "已注册登录自启（launchd ${LABEL}）"
}
write_agent

# ── 命令行入口 ──────────────────────────────────────────
write_cli() {
  cli="$APP_DIR/souse"
  cat > "$cli" <<EOF
#!/bin/sh
# souse 命令行（由安装器生成）
APP_DIR="$APP_DIR"
LABEL="$LABEL"
case "\${1:-status}" in
  start)   launchctl kickstart -k "gui/\$(id -u)/\$LABEL" ;;
  stop)    launchctl bootout "gui/\$(id -u)/\$LABEL" 2>/dev/null ;;
  restart) launchctl kickstart -k "gui/\$(id -u)/\$LABEL" ;;
  status)  launchctl print "gui/\$(id -u)/\$LABEL" 2>/dev/null | sed -n '1,12p' || echo "未注册" ;;
  logs)    tail -n "\${2:-80}" "\$APP_DIR/logs/souse.log" ;;
  tunnel)  sh "\$APP_DIR/tunnel.sh" ;;
  update)  curl -fsSL https://souse.dpxon.com/install-mac.sh | sh ;;
  version) cat "\$APP_DIR/VERSION" 2>/dev/null ;;
  *)       echo "用法: souse {start|stop|restart|status|logs [n]|tunnel|update|version}" ;;
esac
EOF
  chmod +x "$cli"
  if [ -w /usr/local/bin ] 2>/dev/null; then
    ln -sf "$cli" /usr/local/bin/souse
    ok "命令已装：/usr/local/bin/souse"
  else
    mkdir -p "$HOME/.local/bin"
    ln -sf "$cli" "$HOME/.local/bin/souse"
    ok "命令已装：$HOME/.local/bin/souse"
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) warn "把 $HOME/.local/bin 加进 PATH 才能直接用 souse 命令（~/.zshrc 里加一行）" ;;
    esac
  fi
}
write_cli

# ── 起服务并报告 ────────────────────────────────────────
if [ "${SOUSE_NO_START:-0}" != "1" ]; then
  info "启动服务"
  launchctl kickstart -k "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
  i=0
  while [ $i -lt 40 ]; do
    sleep 0.5
    i=$((i + 1))
    if curl -fsS --max-time 2 "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then break; fi
  done
fi

LAN=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
printf '\n'
printf '  %s本机访问：%s http://127.0.0.1:%s\n' "$C_GRN" "$C_RST" "$PORT"
[ -n "$LAN" ] && printf '  %s局域网  ：%s http://%s:%s   （同一 WiFi 的手机/住户可用）\n' "$C_GRN" "$C_RST" "$LAN" "$PORT"
printf '  安装目录： %s\n' "$APP_DIR"
printf '  配置    ： %s\n' "$APP_DIR/config.yaml"
printf '  日志    ： %s\n' "$LOG_FILE"

if [ -f "$LOG_FILE" ]; then
  U=$(grep -o 'Username: [^"]*' "$LOG_FILE" 2>/dev/null | tail -1 | awk '{print $2}')
  P=$(grep -o 'Password: [^"]*' "$LOG_FILE" 2>/dev/null | tail -1 | awk '{print $2}')
  [ -n "$U" ] && printf '  %s用户名  ：%s %s\n' "$C_YEL" "$C_RST" "$U"
  [ -n "$P" ] && printf '  %s初始密码：%s %s\n' "$C_YEL" "$C_RST" "$P"
  printf '  （只显示一次；重装不会改密码）\n'
fi

printf '\n'
printf '  %s公网访问：%s 运行  souse tunnel  跟着提示开通（Cloudflare Tunnel，免公网 IP）\n' "$C_BLU" "$C_RST"
printf '\n'
