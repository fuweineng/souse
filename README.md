# souse.neng.page

[Souse · 出租屋智能管理平台](https://souse.neng.page) 项目介绍站，GitHub Pages 托管。

- 单文件静态站：`index.html`
- 自定义域名：`CNAME` → souse.neng.page（Cloudflare 橙云代理）
- 修改内容后推送到 `main`，Pages 自动发布

## 在线试用入口

官网的「在线试用」按钮统一指向 **https://demo.neng.page/login**（正式后台 `:8080`）。

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

配套的公开入口来自 CT203 的 cloudflared 隧道 ingress：

```yaml
  - hostname: demo.neng.page
    service: http://192.168.100.65:8080
```

DNS：Cloudflare CNAME `demo.neng.page` → `<tunnel-id>.cfargotunnel.com`（proxied）。
注意 Cloudflare Universal SSL **只覆盖一级子域**，所以入口用 `demo.neng.page` 而不是 `demo.souse.neng.page`。
