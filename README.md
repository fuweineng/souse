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

官网的「在线试用」按钮统一指向 **https://souse.dpxon.com/login**（正式后台 `:8080`，官网与应用同域）。

> 2026-11-11：正式入口从 `app.dpxon.com` 改为 `cz.dpxon.com`，与住户在用的 `cz.neng.page` 同源并行；
> `app.dpxon.com` 已停用（CT203 Caddy 返回 410），不要再往任何页面写它。
>
> 2026-11-16：以上两个 `cz.*` 入口**都已收掉**，统一 301 到 `https://souse.dpxon.com`（详见文末「入口收敛」）。

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
sqlite3 "$DB" "UPDATE users SET password='***' WHERE username='trial';"

# 隐藏/停用试用入口
sqlite3 "$DB" "UPDATE users SET status='disabled' WHERE username='trial';"
```

配套的公开入口来自 CT203 的 cloudflared 隧道 ingress（宿主入口在 CT204，`/etc/cloudflared/config.yml`）：

```yaml
  - hostname: cz.dpxon.com
    service: https://192.168.100.53
    originRequest:
      originServerName: cz.dpxon.com
      noTLSVerify: true
```

DNS：Cloudflare CNAME `cz.dpxon.com` → `b995ad32-d007-4dff-9e7c-f4aede454e36.cfargotunnel.com`（proxied）。
`cz.dpxon.com` 与 `cz.neng.page` 是同一台源站（`192.168.100.65:8080`，`/api/*` 走 `192.168.100.2:8092`）的两个入口，两边并行，互不跳转。
（↑ 2026-11-16 起这条**不再成立**：两者都已 301 到 `https://souse.dpxon.com`，见下方收敛说明。）

> 2026-11-16（入口收敛）：正版入口统一为 **https://souse.dpxon.com/**，本域只当**应用入口**：
> `/` 直接 `302 /login`（首页文案不再挂在这里），`robots.txt` 全站 Disallow，`sitemap.xml` 301 到 `https://dpxon.com/sitemap.xml`；
> 仍保留的静态文件只有安装/文档类（`install.sh`、`install.ps1`、`install-mac.sh`、`downloads.html`、`agent.html`、`site-assets/`）。
> 对外的产品介绍已迁到 **https://dpxon.com/**（展示页，souse 是其中一个项目），数据源 `/root/hub/projects.json` 的 `showcase` 段，生成脚本 `/root/hub/showcase.py`。
>
> `cz.neng.page` 与 `cz.dpxon.com`（VPS 154.94.237.100 的 nginx）都已改为**只作跳转**：页面/静态 301 → `https://souse.dpxon.com`（保留路径与查询串），
> 仅 `/healthz`、`/api/`、`/mcp`（`cz.dpxon.com` 另有 `/nginx-health`）仍直连 `127.0.0.1:8080`，供监控探针、HLS 播放器、脚本与 MCP 客户端使用
> （MCP 是 POST，跟随 301 会丢 body，所以必须保留直连）。
> 官网登录表单 `site-assets/login.js` 已改为同源 `/api/auth/login` + `/admin`，不再跨域打 `cz.neng.page`。
> 回滚点（VPS `/root/nginx-bak/`）：`cz-nengpage.bak-redirect-20261116-150611`、`cz-dpxon.bak-redirect-20261116-155151`
> → 还原对应 `sites-available/*` 并 `systemctl reload nginx`。

注意 Cloudflare Universal SSL **只覆盖一级子域**，所以入口用 `cz.dpxon.com` 而不是 `app.souse.dpxon.com`。