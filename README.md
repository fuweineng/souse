# souse.neng.page

[Souse · 出租屋智能管理平台](https://souse.dpxon.com) 项目介绍站，GitHub Pages 托管。

- 单文件静态站：`index.html`
- 自定义域名：`CNAME` → souse.neng.page（Cloudflare 橙云代理）
- 修改内容后推送到 `main`，Pages 自动发布

## 安装入口（本仓库同时承担发布）

| 路径 | 内容 |
|------|------|
| `/install.sh` | 一行安装脚本：`curl -fsSL https://souse.dpxon.com/install.sh \| sudo sh` |
| `/downloads.html` | 下载页，运行时读 GitHub Releases API 列出各平台安装包 |

安装包本身放在本仓库的 **Releases**（`gh release create v1.0.0 ...`），因为 GitHub Pages 仓库天然是公网可访问的静态空间，安装脚本按 `releases/latest` 取最新版：

```bash
# 打包（在能访问 CT215 产物的机器上）
tar -czf souse-linux-amd64.tar.gz souse-linux-amd64   # 内含 610souse / web/static / assets / fonts / config.example.yaml
sha256sum souse-linux-amd64.tar.gz > souse-linux-amd64.tar.gz.sha256

# 发布
gh release create v1.0.1 souse-linux-amd64.tar.gz{,.sha256} -R fuweineng/souse --notes-file RELEASE_NOTES.md
```

`install.sh` 的约定：装在 `/opt/souse`，systemd 单元 `souse.service`，配置 `/opt/souse/config.yaml`，数据 `/opt/souse/data/db/souse.db`，备份定时器 `souse-backup.timer`（每 6 小时，保留 30 天），管理命令 `sousectl`。

## 在线试用入口

官网的「在线试用」按钮统一指向 **https://app.dpxon.com/login**（正式后台 `:8080`）。

- 试用账号：`trial` / `souse2026`
- 账号范围：仅「试用演示楼」（building `DEMO`）——6 间房（4 在租 / 2 空置）+ 4 位演示住户 + 7 笔演示账单，看不到任何真实房源
- 有效期：`users.expires_at`（默认 30 天，到期自动拒绝登录）

维护命令（在 CT215 上执行）：

```bash
DB=/home/debian/souse/data/db/souse.db

# 查看试用账号
sqlite3 -header "$DB" "SELECT id,username,managed_buildings,expires_at,plan FROM users WHERE username='trial';"

# 续期 30 天
sqlite3 "$DB" "UPDATE users SET expires_at=datetime('now','+30 days') WHERE username='trial';"

# 改密码：先用 bcrypt 生成哈希（cost 10），再写入
sqlite3 "$DB" "UPDATE users SET password='<bcrypt hash>' WHERE username='trial';"

# 隐藏/停用试用入口
sqlite3 "$DB" "UPDATE users SET status='disabled' WHERE username='trial';"
```

配套的公开入口来自 CT203 的 cloudflared 隧道 ingress（宿主入口在 CT204，`/etc/cloudflared/config.yml`）：

```yaml
  - hostname: app.dpxon.com
    service: https://192.168.100.53
    originRequest:
      originServerName: app.dpxon.com
      noTLSVerify: true
```

DNS：Cloudflare CNAME `app.dpxon.com` → `b995ad32-d007-4dff-9e7c-f4aede454e36.cfargotunnel.com`（proxied）。
`app.dpxon.com` 与旧的 `cz.neng.page` 是同一台源站（`192.168.100.65:8080`）的两个入口，两边并行。

注意 Cloudflare Universal SSL **只覆盖一级子域**，所以入口用 `app.dpxon.com` 而不是 `app.souse.dpxon.com`。

