#!/bin/sh
# souse — 一行安装：curl -fsSL https://souse.dpxon.com/install.sh | sudo sh
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

# 下载加速镜像（国内直连 GitHub Releases 常见 50KB/s，103MB 要半小时）
# 仅在 GitHub 直连 60 秒下不完时才启用；SHA256 始终校验，镜像篡改会被拦下。
# 覆盖：SOUSE_MIRROR="https://my.mirror/"   关闭：SOUSE_MIRROR=off
MIRRORS="${SOUSE_MIRROR:-https://gh-proxy.com/,https://ghfast.top/,https://ghproxy.net/}"
[ "$MIRRORS" = "off" ] && MIRRORS=""

info() { printf '%s[INFO]%s %s\n' "$C_BLU" "$C_RST" "$*"; }
ok()   { printf '%s[OK]%s %s\n'   "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$C_YEL" "$C_RST" "$*"; }
die()  { printf '%s[ERR]%s %s\n'  "$C_RED" "$C_RST" "$*" >&2; exit 1; }

MODE="install"
MIRROR_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --channel)     shift ;;
    --update-only) MODE="update"; shift ;;
    --wizard-only) MODE="wizard"; shift ;;
    --mirror-only) MIRROR_ONLY=1; shift ;;
    --dir)         APP_DIR="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
souse 安装脚本

用法: curl -fsSL https://souse.dpxon.com/install.sh | sudo sh -s -- [选项]

选项:
  --update-only   只更新程序，保留数据与配置
  --wizard-only   只重建配置
  --mirror-only   跳过 GitHub 直连，直接用加速镜像（GitHub 被墙时用）
  --dir <路径>    安装目录（默认 /opt/souse）
  -h, --help      显示帮助

装完后:
  sousectl start|stop|restart|status|logs|backup|backups|restore|update|password
  管理台 http://<本机IP>:8080

环境变量:
  SOUSE_MIRROR   下载镜像前缀，逗号分隔多个；off 关闭镜像
                 默认 https://gh-proxy.com/,https://ghfast.top/,https://ghproxy.net/
                 仅当 GitHub 直连 60 秒下不完时启用，SHA256 始终校验
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
Documentation=https://souse.dpxon.com
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
  # 热备：不停服
  sqlite3 "$DB" ".backup '$out'"
else
  # 没有 sqlite3：停服后把 db + wal + shm 作为一组拷走。
  # 只拷 .db 会丢还在 WAL 里未落盘的数据（实测恢复后数据不全）。
  echo "sqlite3 不可用，停服拷贝 db/wal/shm（约 2 秒）"
  systemctl stop souse 2>/dev/null || true
  cp "$DB" "$out"
  [ -f "$DB-wal" ] && cp "$DB-wal" "$out-wal" || true
  [ -f "$DB-shm" ] && cp "$DB-shm" "$out-shm" || true
  systemctl start souse 2>/dev/null || true
fi

sha256sum "$out" > "$out.sha256"
chown souse:souse "$out" "$out.sha256" 2>/dev/null || true
[ -f "$out-wal" ] && chown souse:souse "$out-wal" 2>/dev/null || true
[ -f "$out-shm" ] && chown souse:souse "$out-shm" 2>/dev/null || true
find "$APP_DIR/data/backups" -name 'souse-*.db' -mtime +30 -delete 2>/dev/null || true
find "$APP_DIR/data/backups" -name 'souse-*.db.sha256' -mtime +30 -delete 2>/dev/null || true
find "$APP_DIR/data/backups" -name 'souse-*.db-wal' -mtime +30 -delete 2>/dev/null || true
find "$APP_DIR/data/backups" -name 'souse-*.db-shm' -mtime +30 -delete 2>/dev/null || true
echo "backup ok: $out"
EOS
  chmod 755 /usr/local/lib/souse/backup.sh

  cat > "/etc/systemd/system/${SERVICE_NAME}-backup.service" <<EOF
[Unit]
Description=souse 数据库备份

[Service]
Type=oneshot
# 以 root 运行：没有 sqlite3 时需要停/起 souse 服务来拿一致副本
User=root
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
  update)  curl -fsSL https://souse.dpxon.com/install.sh | sh -s -- --update-only ;;
  password|mkpasswd)
           journalctl -u "$SERVICE" --no-pager | sed -n 's/.*Password: *\([A-Za-z0-9]\{6,\}\).*/\1/p' | tail -1 | grep . || e "日志里没有初始密码（可能已改过）" ;;
  backup)  systemctl start "$SERVICE-backup.service" && g "备份完成，见 $APP_DIR/data/backups" ;;
  backups) ls -1t "$APP_DIR/data/backups"/*.db 2>/dev/null | head -10 || e "还没有备份" ;;
  restore)
    [ $# -ge 1 ] || e "用法: sudo sousectl restore <备份文件.db>（先 sousectl backups 看有哪些）"
    B="$1"
    [ -f "$B" ] || e "文件不存在: $B"
    printf '将用 %s 覆盖当前数据库，服务会重启。继续？[y/N] ' "$B"
    read -r ans
    case "$ans" in y|Y|yes) ;; *) e "已取消" ;; esac
    systemctl stop "$SERVICE"
    cp -f "$B" "$APP_DIR/data/db/souse.db"
    rm -f "$APP_DIR/data/db/souse.db-wal" "$APP_DIR/data/db/souse.db-shm"
    # 备份里带 wal/shm 时一并还原（没有 sqlite3 的机器用这种备份）
    [ -f "$B-wal" ] && cp -f "$B-wal" "$APP_DIR/data/db/souse.db-wal" || true
    [ -f "$B-shm" ] && cp -f "$B-shm" "$APP_DIR/data/db/souse.db-shm" || true
    chown -R "$SERVICE:$SERVICE" "$APP_DIR/data/db/"
    systemctl start "$SERVICE"
    sleep 2
    systemctl is-active --quiet "$SERVICE" && g "已恢复并重启: $B" || e "恢复后服务没起来，看 journalctl -u $SERVICE -n 50"
    ;;
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
  backups                  列出最近 10 份备份
  restore <文件>           用备份覆盖数据库并重启（会二次确认）
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

SKIP_DL=0
if [ "$CUR" = "$VERSION" ] && [ -x "$APP_DIR/$BIN_NAME" ]; then
  info "已经是 ${VERSION}，跳过下载，只重建服务与配置（修复模式）"
  SKIP_DL=1
elif [ -n "$CUR" ]; then
  info "当前 ${CUR} → 目标 ${VERSION}"
else
  info "待安装版本 ${VERSION}"
fi

if [ "$SKIP_DL" != "1" ]; then
ASSET="souse-linux-${ARCH}.tar.gz"
BASE="https://github.com/${REPO}/releases/download/${VERSION}"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/souse.XXXXXX" 2>/dev/null) || TMP=$(mktemp -d /tmp/souse.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

info "下载 ${ASSET} ..."
DEST="${TMP}/${ASSET}"

# 直连 60 秒下不完就换镜像；--mirror-only 直接走镜像
GOT_IT=0
if [ "$MIRROR_ONLY" != "1" ]; then
  if fetch "${BASE}/${ASSET}" "$DEST" 60; then
    GOT_IT=1
  else
    warn "GitHub 直连 60 秒未完成，改用加速镜像"
  fi
else
  info "按要求跳过 GitHub 直连（--mirror-only）"
fi

if [ "$GOT_IT" != "1" ]; then
  OLDIFS=$IFS; IFS=','
  for m in $MIRRORS; do
    IFS=$OLDIFS
    [ -n "$m" ] || continue
    info "尝试镜像: $m"
    if fetch "${m}${BASE}/${ASSET}" "$DEST" 1800; then
      ok "镜像下载成功: $m"
      GOT_IT=1
      break
    fi
  done
  IFS=$OLDIFS
fi

if [ "$GOT_IT" != "1" ]; then
  [ "$MIRROR_ONLY" = "1" ] && die "所有镜像都失败；去掉 --mirror-only 或用 SOUSE_MIRROR=off 走 GitHub 直连"
  warn "镜像都不可用，回到 GitHub 直连（不限时，可能很慢）"
  fetch "${BASE}/${ASSET}" "$DEST" 1800 || die "下载失败: ${BASE}/${ASSET}"
fi

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
fi  # SKIP_DL

mkdir -p "$APP_DIR/data/db" "$APP_DIR/data/backups" "$APP_DIR/logs"
gen_config
ensure_user
chown -R "$SERVICE_NAME:$SERVICE_NAME" "$APP_DIR"
chmod 600 "$APP_DIR/config.yaml" 2>/dev/null || true

write_service
write_cli

# 尽量装上 sqlite3：有它备份就能不停服热备（失败不阻断安装）
if ! command -v sqlite3 >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
  info "安装 sqlite3（用于不停服热备份）..."
  if apt-get install -y -qq sqlite3 >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq sqlite3 >/dev/null 2>&1; }; then
    ok "sqlite3 就绪"
  else
    warn "sqlite3 没装上，备份时会短暂停服（约 2 秒）"
  fi
fi

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
printf '  管理     sousectl start|stop|restart|status|logs|backup|backups|restore|update\n\n'

PW=$(journalctl -u "$SERVICE_NAME" --no-pager 2>/dev/null | sed -n 's/.*Password: *\([A-Za-z0-9]\{6,\}\).*/\1/p' | tail -1) || PW=""
if [ -n "$PW" ]; then
  printf '  %s管理员 admin   初始密码 %s%s\n' "$C_GRN" "$PW" "$C_RST"
  printf '  %s忘了就执行: sudo sousectl password%s\n\n' "$C_DIM" "$C_RST"
else
  printf '  管理员 admin（初始密码: sudo sousectl password）\n\n'
fi
printf '  外网访问：Cloudflare 隧道指向 http://127.0.0.1:8080\n'
