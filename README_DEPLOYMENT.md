# 🚀 快速部署指南

## 三种部署方式对比

| 方式 | 适用场景 | 难度 | 费用 | 推荐度 |
|------|---------|------|------|--------|
| **Cloudflare Tunnel** | 中长期演示 | ⭐⭐ | 免费 | ⭐⭐⭐⭐⭐ |
| **ngrok** | 临时演示 | ⭐ | 免费（有限制） | ⭐⭐⭐ |
| **本地访问** | 开发测试 | ⭐ | 免费 | ⭐⭐ |

---

## 🌟 方案 1：Cloudflare Tunnel（推荐）

### 优势
- ✅ 完全免费，无流量限制
- ✅ 自定义域名，URL 固定不变
- ✅ 无访问警告页面
- ✅ 全球 CDN 加速
- ✅ 更专业的体验

### 快速开始

**一键配置（推荐）：**
```bash
./setup-cloudflare.sh
```

脚本会自动完成：
1. 检查 cloudflared 安装
2. 登录 Cloudflare
3. 创建隧道
4. 配置域名和 DNS
5. 生成配置文件

**启动服务：**
```bash
docker-compose --profile cloudflare up -d --build
```

**访问服务：**
```
https://your-domain.com
```

📖 **详细文档：** [CLOUDFLARE_SETUP.md](CLOUDFLARE_SETUP.md)

---

## ⚡ 方案 2：ngrok（快速演示）

### 优势
- ✅ 零配置，即开即用
- ✅ 自动 HTTPS
- ✅ 适合临时演示

### 快速开始

**1. 启动 Docker 服务：**
```bash
docker-compose up -d --build
```

**2. 启动 ngrok：**
```bash
ngrok http 80
```

**3. 访问服务：**
使用 ngrok 提供的 URL（如 `https://xxxx.ngrok-free.app`）

📖 **详细文档：** [DEPLOY.md](DEPLOY.md)

---

## 💻 方案 3：本地访问

### 快速开始

**Docker 部署：**
```bash
docker-compose up -d --build
```

**本地开发：**
```bash
bash start.sh
```

**访问服务：**
- Docker: `http://localhost`
- 本地开发: `http://localhost:5173`

---

## 🔧 常用命令

### Docker 管理
```bash
# 启动服务（基础）
docker-compose up -d --build

# 启动服务（含 Cloudflare Tunnel）
docker-compose --profile cloudflare up -d --build

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart
```

### 测试部署
```bash
# 运行自动化测试
./test-deploy.sh
```

---

## 📝 默认账户

- **用户名：** `admin`
- **密码：** `changeme123`

⚠️ **重要：** 首次登录后请立即修改密码！

---

## 🆘 故障排查

### 容器无法启动
```bash
docker-compose logs
docker-compose down
docker-compose up -d --build
```

### 数据库初始化失败
```bash
rm -rf ./data/credit_mgmt.db
docker-compose restart backend
```

### Cloudflare Tunnel 连接失败
```bash
docker-compose logs cloudflared
```

常见问题：
- 凭证文件路径错误
- Tunnel ID 不匹配
- DNS 未生效（等待 5 分钟）

---

## 📚 更多文档

- [Cloudflare Tunnel 详细配置](CLOUDFLARE_SETUP.md)
- [ngrok 部署指南](DEPLOY.md)
- [项目说明](README.md)

---

## 🎯 推荐流程

1. **开发阶段：** 使用 `bash start.sh` 本地开发
2. **演示阶段：** 使用 Cloudflare Tunnel 或 ngrok
3. **生产环境：** 考虑 Railway / Render 等云平台

---

需要帮助？查看详细文档或提交 Issue！
