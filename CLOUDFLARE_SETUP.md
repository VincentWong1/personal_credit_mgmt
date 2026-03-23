# Cloudflare Tunnel 部署指南

## 为什么选择 Cloudflare Tunnel？

相比 ngrok，Cloudflare Tunnel 提供：
- ✅ **完全免费**，无流量限制
- ✅ **自定义域名**，URL 不会变化
- ✅ **无访问警告**，更专业的体验
- ✅ **全球 CDN**，访问速度更快
- ✅ **更稳定**，基于 Cloudflare 基础设施

## 前置条件

1. 拥有一个域名（可以使用免费域名服务如 Freenom）
2. 注册 Cloudflare 账号：https://dash.cloudflare.com/sign-up
3. 将域名的 DNS 托管到 Cloudflare

## 快速开始

### 方法 1：使用 Docker Compose（推荐）

#### 步骤 1：安装 cloudflared CLI

**macOS:**
```bash
brew install cloudflare/cloudflare/cloudflared
```

**Linux:**
```bash
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

**Windows:**
下载：https://github.com/cloudflare/cloudflared/releases/latest

#### 步骤 2：登录 Cloudflare

```bash
cloudflared tunnel login
```

这会打开浏览器，选择你的域名并授权。

#### 步骤 3：创建隧道

```bash
# 创建隧道
cloudflared tunnel create credit-mgmt

# 记录输出的 Tunnel ID（类似：a1b2c3d4-e5f6-7890-abcd-ef1234567890）
```

创建成功后，会在 `~/.cloudflared/` 目录生成凭证文件。

#### 步骤 4：复制凭证文件

```bash
# 创建 cloudflared 目录
mkdir -p cloudflared

# 复制凭证文件（替换 TUNNEL_ID 为你的实际 Tunnel ID）
cp ~/.cloudflared/TUNNEL_ID.json cloudflared/credentials.json
```

#### 步骤 5：配置隧道

编辑 `cloudflared/config.yml`，替换以下内容：

```yaml
tunnel: YOUR_TUNNEL_ID  # 替换为你的 Tunnel ID
credentials-file: /etc/cloudflared/credentials.json

ingress:
  - hostname: demo.yourdomain.com  # 替换为你的域名
    service: http://frontend:80
  - service: http_status:404
```

#### 步骤 6：配置 DNS

```bash
# 创建 DNS 记录（替换域名和 Tunnel ID）
cloudflared tunnel route dns credit-mgmt demo.yourdomain.com
```

#### 步骤 7：启动服务

```bash
# 启动包含 Cloudflare Tunnel 的完整服务
docker-compose --profile cloudflare up -d --build
```

#### 步骤 8：访问服务

现在可以通过你的域名访问服务：
- 前端：`https://demo.yourdomain.com`
- 后端 API：`https://demo.yourdomain.com/api/`

---

### 方法 2：仅使用 ngrok（快速演示）

如果你只是临时演示，可以继续使用 ngrok：

```bash
# 启动 Docker 服务（不包含 cloudflared）
docker-compose up -d --build

# 在另一个终端启动 ngrok
ngrok http 80
```

---

## 常用命令

### Docker Compose 命令

```bash
# 启动服务（不含 Cloudflare Tunnel）
docker-compose up -d --build

# 启动服务（含 Cloudflare Tunnel）
docker-compose --profile cloudflare up -d --build

# 查看日志
docker-compose logs -f
docker-compose logs -f cloudflared  # 仅查看隧道日志

# 停止服务
docker-compose down
docker-compose --profile cloudflare down

# 重启服务
docker-compose restart
```

### Cloudflare Tunnel 管理

```bash
# 查看所有隧道
cloudflared tunnel list

# 查看隧道信息
cloudflared tunnel info credit-mgmt

# 删除隧道
cloudflared tunnel delete credit-mgmt

# 清理未使用的隧道
cloudflared tunnel cleanup credit-mgmt
```

---

## 故障排查

### 1. 隧道无法连接

**检查隧道状态：**
```bash
docker-compose logs cloudflared
```

**常见问题：**
- 凭证文件路径错误：确保 `cloudflared/credentials.json` 存在
- Tunnel ID 不匹配：检查 `config.yml` 中的 tunnel ID
- DNS 未生效：等待 DNS 传播（最多 5 分钟）

### 2. 502 Bad Gateway

**原因：** 前端容器未启动或网络配置错误

**解决：**
```bash
# 检查容器状态
docker-compose ps

# 检查网络连接
docker-compose exec cloudflared ping frontend
```

### 3. 403 Forbidden

**原因：** 域名未正确配置或未授权

**解决：**
```bash
# 重新配置 DNS
cloudflared tunnel route dns credit-mgmt demo.yourdomain.com

# 检查 Cloudflare Dashboard 中的 DNS 记录
```

---

## 安全建议

1. **修改默认密码**：首次登录后立即修改管理员密码
2. **启用访问控制**：在 Cloudflare Dashboard 配置 Access 策略
3. **定期备份数据**：备份 `./data/` 目录
4. **监控日志**：定期检查 `docker-compose logs`

---

## 对比：ngrok vs Cloudflare Tunnel

| 特性 | ngrok | Cloudflare Tunnel |
|------|-------|-------------------|
| 价格 | 免费版有限制 | 完全免费 |
| 自定义域名 | 付费功能 | ✅ 免费 |
| URL 稳定性 | 每次重启变化 | ✅ 固定 |
| 访问限制 | 40 req/min | ✅ 无限制 |
| 警告页面 | ❌ 有 | ✅ 无 |
| 配置复杂度 | ⭐ 简单 | ⭐⭐ 中等 |
| 全球加速 | ❌ | ✅ CDN |

---

## 生产环境部署

如果需要长期稳定运行，建议使用云平台：

### Railway（推荐）

1. 注册：https://railway.app
2. 连接 GitHub 仓库
3. 自动部署，提供免费域名
4. 支持环境变量和数据持久化

### Render

1. 注册：https://render.com
2. 创建 Web Service
3. 连接 GitHub 仓库
4. 免费额度：750 小时/月

---

## 获取帮助

- Cloudflare Tunnel 文档：https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- Cloudflare 社区：https://community.cloudflare.com/
- 项目 Issues：https://github.com/VincentWong1/personal_credit_mgmt/issues
