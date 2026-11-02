#!/bin/sh
# souse — 一行安装：curl -fsSL https://souse.neng.page/install.sh | sudo sh
#
# 目标：一台 Linux（有 systemd）电脑，一行命令装完，自动打印管理员密码。
# 产物来源：https://github.com/fuweineng/souse/releases
#
# 注意：本脚本按 POSIX sh 编写（dash 也能跑），不依赖 bash。

set -eu

REPO="fuweineng/souse"
APP_DIR="/opt/souse"
BIN_NAME="610souse"
SERVICE_NAME="souse"

C_RED=$(printf '\033[31m'); C_GRN=$(printf '\033[32m'); C_YEL=$(printf '\033[33m')
C_BLU=$(printf '\033[34m'); C_DIM=$(printf '\033[2m');  C_RST=$(printf '\033[0m')
if [ ! -t 1 ]; then C_RED=; C_GRN=; C_YEL=; C_BLU=; C_DIM=; C_RST=; fi

info() { printf '%s[INFO]%s %s\n' "$C_BLU" "$C_RST" "$*"; }
ok()   { printf '%s[OK]%s %s\n'   "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$C_YEL" "$C_RST" "$*"; }
die()  { printf '%s[ERR]%s %s\n'  "$C_RED" "$C_RST" "$*" >&2; exit 1; }

MODE="install"
while [ $# -gt 0 ]; do
  case "$1" in
    --channel)     shift ;;
    --update-only) MODE="update"; shift ;;
    --wizard-only) MODE="wizard"; shift ;;
    --dir)         APP_DIR="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
souse 安装脚本

用法: curl -fsSL https://souse.neng.page/install.sh | sudo sh -s -- [选项]

选项:
  --update-only   只更新程序，保留数据与配置
  --wizard-only   只重建配置
  --dir <路径>    安装目录（默认 /opt/souse）
  -h, --help      显示帮助

装完后:
  sousectl start|stop|restart|status|logs|backup|update|password
  管理台 http://<本机IP>:8080
EOF
      exit 0 ;;
    *) die "未知参数: $1（用 --help 查看）" ;;
  esac
done

need_root() { [ "$(id -u)" -eq 0 ] || die "需要 root：用 sudo sh 运行"; }

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    *) die "不支持的架构: $(uname -m)" ;;
  esac
}

detect_os() {
  [ "$(uname -s)" = "Linux" ] || die "本脚本只装 Linux；macOS / Windows 见下载页"
  command -v systemctl >/dev/null 2>&1 || die "需要 systemd"
}

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 --connect-timeout 15 --max-time "${3:-1800}" "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T "${3:-1800}" -O "$2" "$1"
  else
    die "需要 curl 或 wget"
  fi
}

fetch_stdout() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 15 --max-time "${2:-60}" "$1"
  else
    wget -qO- -T "${2:-60}" "$1"
  fi
}

latest_version() {
  local body
  body=$(fetch_stdout "https://api.github.com/repos/${REPO}/releases/latest") || return 1
  printf '%s' "$body" \
    | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 \
    | sed 's/.*"\([^"]*\)"$/\1/'
}

gen_config() {
  cfg="$APP_DIR/config.yaml"
  [ -f "$cfg" ] && return 0
  [ -f "$APP_DIR/config.example.yaml" ] || die "发布包缺少 config.example.yaml"
  cp "$APP_DIR/config.example.yaml" "$cfg"
  ok "已生成配置: $cfg"
}

ensure_user() {
  if ! id "$SERVICE_NAME" >/dev/null 2>&1; then
    useradd --system --no-create-home --home-dir "$APP_DIR" \
            --shell /usr/sbin/nologin "$SERVICE_NAME"
    ok "已创建系统用户: $SERVICE_NAME"
  fi
}

write_service() {
  cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=souse 出租屋管理系统
Documentation=https://souse.neng.page
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_NAME}
Group=${SERVICE_NAME}
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/${BIN_NAME} ${APP_DIR}/config.yaml
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=${APP_DIR}
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  ok "已写入服务单元: /etc/systemd/system/${SERVICE_NAME}.service"
}

write_backup_timer() {
  mkdir -p /usr/local/lib/souse
  cat > /usr/local/lib/souse/backup.sh <<'EOS'
#!/bin/sh
set -eu
APP_DIR="/opt/souse"
DB="$APP_DIR/data/db/souse.db"
[ -f "$DB" ] || { echo "no db yet: $DB"; exit 0; }
mkdir -p "$APP_DIR/data/backups"
ts=$(date +%Y%m%d-%H%M%S)
out="$APP_DIR/data/backups/souse-$ts.db"
if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "$DB" ".backup '$out'"
else
  cp "$DB" "$out"
fi
sha256sum "$out" > "$out.sha256"
find "$APP_DIR/data/backups" -name 'souse-*.db' -mtime +30 -delete 2>/dev/null || true
find "$APP_DIR/data/backups" -name 'souse-*.db.sha256' -mtime +30 -delete 2>/dev/null || true
echo "backup ok: $out"
EOS
  chmod 755 /usr/local/lib/souse/backup.sh

  cat > "/etc/systemd/system/${SERVICE_NAME}-backup.service" <<EOF
[Unit]
Description=souse 数据库备份

[Service]
Type=oneshot
User=${SERVICE_NAME}
Group=${SERVICE_NAME}
ExecStart=/usr/local/lib/souse/backup.sh
EOF

  cat > "/etc/systemd/system/${SERVICE_NAME}-backup.timer" <<EOF
[Unit]
Description=souse 每 6 小时备份

[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true
RandomizedDelaySec=10m

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload
  ok "已配置每 6 小时自动备份"
}

write_cli() {
  cat > /usr/local/bin/sousectl <<'EOC'
#!/bin/sh
set -eu
APP_DIR="/opt/souse"
SERVICE="souse"
g() { printf '\033[32m%s\033[0m\n' "$*"; }
e() { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || e "请用 sudo sousectl ..."

cmd="${1:-help}"
[ $# -gt 0 ] && shift || true
case "$cmd" in
  start)   systemctl start "$SERVICE";   g "已启动" ;;
  stop)    systemctl stop "$SERVICE";    g "已停止" ;;
  restart) systemctl restart "$SERVICE"; g "已重启" ;;
  status)  systemctl status "$SERVICE" --no-pager ;;
  logs)    journalctl -u "$SERVICE" -f "$@" ;;
  enable)  systemctl enable "$SERVICE";  g "已设为开机自启" ;;
  disable) systemctl disable "$SERVICE"; g "已取消开机自启" ;;
  config)  "${EDITOR:-vi}" "$APP_DIR/config.yaml" && systemctl restart "$SERVICE" && g "已重启" ;;
  update)  curl -fsSL https://souse.neng.page/install.sh | sh -s -- --update-only ;;
  password|mkpasswd)
           journalctl -u "$SERVICE" --no-pager | sed -n 's/.*Password: *\([A-Za-z0-9]\{6,\}\).*/\1/p' | head -1 | grep . || e "日志里没有初始密码（可能已改过）" ;;
  backup)  systemctl start "$SERVICE-backup.service" && g "备份完成，见 $APP_DIR/data/backups" ;;
  version) cat "$APP_DIR/VERSION" 2>/dev/null || echo unknown ;;
  url)     ip -4 route get 1.1.1.1 2>/dev/null | awk '{print "http://"$7":8080"; exit}' || echo "http://127.0.0.1:8080" ;;
  *)
    cat <<'H'
sousectl — souse 管理命令

  start / stop / restart   服务开关
  status                   运行状态
  logs [-n 100]            跟踪日志
  enable / disable         开机自启
  config                   编辑配置并重启
  password                 显示初始管理员密码
  backup                   立即备份数据库
  update                   升级到最新版本（再跑一次安装脚本 --update-only）
  version                  当前版本
  url                      本机访问地址
H
    ;;
esac
EOC
  chmod 755 /usr/local/bin/sousectl
  ok "已安装管理命令: sousectl"
}

# ================= 主流程 =================
need_root
detect_os
ARCH=$(detect_arch)
info "souse 安装器 · 架构 ${ARCH}"

if [ "$MODE" = "wizard" ]; then
  [ -d "$APP_DIR" ] || die "$APP_DIR 不存在，请先正常安装"
  gen_config
  ok "配置就绪: $APP_DIR/config.yaml"
  exit 0
fi

VERSION=$(latest_version) || die "取不到最新版本（检查到 GitHub 的网络）"
[ -n "$VERSION" ] || die "GitHub 没有返回版本号"

CUR=""
[ -f "$APP_DIR/VERSION" ] && CUR=$(cat "$APP_DIR/VERSION")
if [ "$MODE" = "update" ] && [ "$CUR" = "$VERSION" ]; then
  ok "已是最新版本 $VERSION"
  exit 0
fi
if [ -n "$CUR" ]; then info "当前 ${CUR} → 目标 ${VERSION}"; else info "待安装版本 ${VERSION}"; fi

ASSET="souse-linux-${ARCH}.tar.gz"
BASE="https://github.com/${REPO}/releases/download/${VERSION}"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/souse.XXXXXX" 2>/dev/null) || TMP=$(mktemp -d /tmp/souse.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

info "下载 ${ASSET} ..."
fetch "${BASE}/${ASSET}" "${TMP}/${ASSET}" || die "下载失败: ${BASE}/${ASSET}"

if fetch "${BASE}/${ASSET}.sha256" "${TMP}/sum.txt" 60 2>/dev/null; then
  EXP=$(awk '{print $1}' "${TMP}/sum.txt")
  GOT=$(sha256sum "${TMP}/${ASSET}" | awk '{print $1}')
  [ "$EXP" = "$GOT" ] || die "校验失败（期望 $EXP，实际 $GOT）"
  ok "SHA256 校验通过"
else
  warn "缺少 .sha256，跳过校验"
fi

info "解包到 ${APP_DIR} ..."
mkdir -p "$APP_DIR"

tar -xzf "${TMP}/${ASSET}" -C "$TMP"
SRC=$(find "$TMP" -maxdepth 1 -type d -name 'souse-*' | head -1)
[ -n "$SRC" ] || die "压缩包结构异常"

# 覆盖程序文件，但保留用户自己的配置、数据、日志
for item in "$SRC"/*; do
  b=$(basename "$item")
  case "$b" in
    config.yaml) [ -f "$APP_DIR/config.yaml" ] && continue ;;
    data|logs)   continue ;;
  esac
  rm -rf "$APP_DIR/$b"
  cp -a "$item" "$APP_DIR/$b"
done

echo "$VERSION" > "$APP_DIR/VERSION"
chmod 755 "$APP_DIR/$BIN_NAME" 2>/dev/null || true

mkdir -p "$APP_DIR/data/db" "$APP_DIR/data/backups" "$APP_DIR/logs"
gen_config
ensure_user
chown -R "$SERVICE_NAME:$SERVICE_NAME" "$APP_DIR"
chmod 600 "$APP_DIR/config.yaml" 2>/dev/null || true

write_service
write_cli
write_backup_timer

if [ "$MODE" = "update" ]; then
  systemctl restart "$SERVICE_NAME"
else
  systemctl enable --now "$SERVICE_NAME"
fi
systemctl enable --now "${SERVICE_NAME}-backup.timer" >/dev/null 2>&1 || true

sleep 3
if systemctl is-active --quiet "$SERVICE_NAME"; then
  ok "服务已运行"
else
  warn "服务没起来，看日志：journalctl -u ${SERVICE_NAME} -n 50"
fi

IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}') || IP=""
printf '\n'
if [ "$MODE" = "update" ]; then ok "已更新到 ${VERSION}"; else ok "安装完成 ${VERSION}"; fi
printf '  管理台   http://%s:8080\n' "${IP:-127.0.0.1}"
printf '  配置     %s/config.yaml\n' "$APP_DIR"
printf '  数据     %s/data\n' "$APP_DIR"
printf '  管理     sousectl start|stop|restart|status|logs|backup|update\n\n'

PW=$(journalctl -u "$SERVICE_NAME" --no-pager 2>/dev/null | sed -n 's/.*Password: *\([A-Za-z0-9]\{6,\}\).*/\1/p' | head -1) || PW=""
if [ -n "$PW" ]; then
  printf '  %s管理员 admin   初始密码 %s%s\n' "$C_GRN" "$PW" "$C_RST"
  printf '  %s忘了就执行: sudo sousectl password%s\n\n' "$C_DIM" "$C_RST"
else
  printf '  管理员 admin（初始密码: sudo sousectl password）\n\n'
fi
printf '  外网访问：Cloudflare 隧道指向 http://127.0.0.1:8080\n'
