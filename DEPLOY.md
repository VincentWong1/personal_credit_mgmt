# Docker 部署指南

> 💡 **推荐使用 Cloudflare Tunnel**：相比 ngrok，Cloudflare Tunnel 完全免费、无限制、支持自定义域名。详见 [CLOUDFLARE_SETUP.md](CLOUDFLARE_SETUP.md)

---

## 快速选择部署方案

| 方案 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| **Cloudflare Tunnel** | 中长期演示 | 免费、稳定、自定义域名 | 需要域名 |
| **ngrok** | 临时演示 | 即开即用 | 免费版有限制 |
| **本地访问** | 开发测试 | 最简单 | 仅本地访问 |

---

# Docker + ngrok 部署指南（临时演示）

## 前置条件

1. 安装 Docker 和 Docker Compose
2. 安装 ngrok：https://ngrok.com/download
3. 注册 ngrok 账号并获取 authtoken

## 部署步骤

### 1. 配置环境变量

```bash
# 生成 JWT 密钥
export JWT_SECRET_KEY=$(openssl rand -hex 32)

# 或者编辑 .env 文件
cp .env.example .env
# 然后修改 .env 中的 JWT_SECRET_KEY
```

### 2. 启动 Docker 服务

```bash
docker-compose up -d --build
```

等待服务启动完成（约 1-2 分钟）。

### 3. 验证本地服务

```bash
# 检查容器状态
docker-compose ps

# 测试后端健康检查
curl http://localhost:8000/api/health

# 访问前端
open http://localhost
```

### 4. 配置 ngrok

```bash
# 认证（首次使用）
ngrok config add-authtoken YOUR_AUTH_TOKEN

# 启动 ngrok 隧道（映射到本地 80 端口）
ngrok http 80
```

ngrok 会输出类似以下信息：
```
Forwarding  https://xxxx-xxx-xxx-xxx.ngrok-free.app -> http://localhost:80
```

### 5. 访问服务

使用 ngrok 提供的 HTTPS URL 访问你的服务：
- 前端：`https://xxxx-xxx-xxx-xxx.ngrok-free.app`
- 后端 API：`https://xxxx-xxx-xxx-xxx.ngrok-free.app/api/`

默认管理员账户：
- 用户名：`admin`
- 密码：`changeme123`

## 常用命令

```bash
# 查看日志
docker-compose logs -f

# 查看后端日志
docker-compose logs -f backend

# 查看前端日志
docker-compose logs -f frontend

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 停止并删除数据
docker-compose down -v
```

## 故障排查

### 1. 容器无法启动

```bash
# 查看详细日志
docker-compose logs

# 重新构建
docker-compose down
docker-compose up -d --build
```

### 2. 数据库初始化失败

```bash
# 删除数据库文件重新初始化
rm -rf ./data/credit_mgmt.db
docker-compose restart backend
```

### 3. ngrok 访问 403 错误

ngrok 免费版可能会显示警告页面，点击 "Visit Site" 继续访问。

### 4. API 请求失败

检查 CORS 配置和 nginx 反向代理：
```bash
# 测试后端直接访问
curl http://localhost:8000/api/health

# 测试通过 nginx 访问
curl http://localhost/api/health
```

## 生产环境建议

1. **修改默认密码**：首次登录后立即修改管理员密码
2. **使用强密钥**：生成随机的 JWT_SECRET_KEY
3. **数据备份**：定期备份 `./data/` 目录
4. **使用 HTTPS**：ngrok 自动提供 HTTPS，生产环境建议配置自己的证书
5. **限制访问**：配置防火墙规则，只允许必要的端口访问

## ngrok 高级配置

### 固定域名（需要付费版）

编辑 `ngrok.yml`：
```yaml
version: "2"
authtoken: YOUR_AUTH_TOKEN
tunnels:
  credit-mgmt:
    proto: http
    addr: 80
    domain: your-custom-domain.ngrok.io
```

启动：
```bash
ngrok start credit-mgmt
```

### 基本认证（保护服务）

```bash
ngrok http 80 --basic-auth="username:password"
```
