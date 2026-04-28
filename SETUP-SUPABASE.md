# FitTrack Pro · Supabase 接入指南

> 5 分钟一次性配置。完成后所有用户数据存云端，跨设备同步、数据隔离。

---

## Step 1 · 注册 Supabase 并创建项目（2 分钟）

1. 打开 https://supabase.com → 右上角 **Start your project**
2. 用 **GitHub 一键登录**（推荐，免邮箱激活）
3. 进控制台 → 点 **New Project**
4. 填表：

   | 字段 | 填什么 |
   |---|---|
   | Name | `fittrack-pro` |
   | Database Password | 自己起一个强密码（**记下来**，找回数据要用） |
   | Region | **Singapore (Southeast Asia)**（中国大陆访问最快） |
   | Pricing Plan | **Free** |

5. 点 **Create new project**，等 1-2 分钟蓝色进度条走完

---

## Step 2 · 一键导入数据库结构（1 分钟）

1. 项目创建好后，左侧栏点 🛢 **SQL Editor**
2. 点 **+ New query**
3. 用编辑器打开 `supabase-schema.sql`，**全选复制**，粘贴到 Supabase SQL 编辑框
4. 右下角点 **Run**（或按 ⌘+Return）
5. 看到底部绿色 **Success. No rows returned** 即完成
   - 此时已自动创建 9 张表 + 行级安全策略

> 🔍 验证：左侧 **Table Editor** 能看到 profiles / weights / food_records ... 等表

---

## Step 3 · 复制 API 凭证给 CLAW（1 分钟）

1. 左侧栏点 ⚙ **Project Settings**
2. 子菜单 **API**
3. 复制以下 **两个值**，发给 CLAW：

   | 字段 | 在哪里 | 用途 |
   |---|---|---|
   | **Project URL** | 「Project URL」一栏，形如 `https://xxxxxxxx.supabase.co` | 前端连接地址 |
   | **anon public key** | 「Project API keys」→ 复制 **anon** 行的 key（很长一串 `eyJ...`） | 前端调用密钥 |

> ⚠️ **不要给 service_role key**！那是后台管理员 key，泄露=数据库门户大开。anon key 安全公开。

---

## Step 4 · 把凭证发给 CLAW（30 秒）

直接在对话里粘贴，例如：

```
URL: https://abcdefgh.supabase.co
KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ...（很长）
```

CLAW 收到后会：
- 写入 `fit-app-pro.html` 配置区
- 重新部署到 GitHub Pages
- 1-2 分钟后，应用就能用云端账号登录了

---

## 已开启的功能

✅ 手机号 + 密码注册登录（手机号在内部映射为 email，体验上仍是手机号）
✅ 跨设备同步（同一账号不同手机/电脑都能看到全部数据）
✅ 数据隔离（每个账号互不可见对方数据）
✅ 永久免费档（500MB DB / 50k 月活，单人随便用）

---

## 后续运维

### 想真发短信验证码？

Supabase → **Authentication** → **Providers** → 开启 **Phone**，配置 Twilio / Vonage 等短信网关（按发送量收费，约 ¥0.3/条）。前端代码无需改动。

### 看用户数据？

Supabase → **Table Editor**，每张表都能可视化浏览/筛选/导出 CSV。

### 数据备份？

Supabase 免费档每天自动备份近 7 天，控制台 **Database → Backups** 可下载。

### 想自己改 SQL 结构？

直接在 SQL Editor 跑 `alter table ...`，前端代码会自动适配（前端只用现有字段，新增字段不影响）。

---

## 常见问题

**Q：我已经在用 localStorage 版本，旧数据怎么办？**
A：登录后 app 会自动检测本地数据并提示一键迁移到云账号。

**Q：忘记密码？**
A：当前版本暂不支持自助找回，请联系 CLAW 在 Supabase 后台重置（也可后续接入邮箱找回）。

**Q：手机号格式？**
A：仅支持中国大陆 11 位手机号（`13/14/15/16/17/18/19` 开头）。

**Q：为什么不用真短信？**
A：短信网关需付费，演示阶段用 email 模拟手机号，体验完全相同。需要随时升级。
