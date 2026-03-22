# 临时演示快速指南

## 场景
需要给外地的同事/客户实时演示系统功能，让他们通过公网访问。

## 前置条件

### 1. 安装 ngrok

**macOS:**
```bash
brew install ngrok
```

**其他系统:**
访问 https://ngrok.com/download 下载对应版本

**验证安装:**
```bash
ngrok --version
```

### 2. 注册 ngrok 账号并获取令牌

1. 访问 https://dashboard.ngrok.com/get-started/your-authtoken
2. 注册或登录
3. 复制你的 authtoken
4. 在本地配置：
```bash
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE
```

## 快速开始

### 方式 A：推荐 - 一键启动（包含穿透）

```bash
# 第一个终端：启动本地服务
bash start.sh

# 第二个终端：启动穿透
bash tunnel.sh
```

脚本会自动显示：
- ✅ 前端访问地址（分享给别人）
- ✅ 后端 API 地址
- ✅ 默认登录账户
- ✅ API 文档链接

### 方式 B：手动启动穿透（如需自定义）

```bash
# 确保本地服务已运行（localhost:5173 前端, localhost:8001 后端）
bash start.sh

# 在另一个终端手动启动 ngrok
ngrok http 5173    # 前端穿透
ngrok http 8001    # 后端穿透
```

## 使用指南

### 启动后看到的信息

```
[LINK] 前端访问地址: https://xxxx-xxxx-xxxx.ngrok.io
[LINK] 后端 API 基础: https://yyyy-yyyy-yyyy.ngrok.io
[LINK] API 文档: https://yyyy-yyyy-yyyy.ngrok.io/docs

复制给别人的链接:
  https://xxxx-xxxx-xxxx.ngrok.io
```

### 分享给外人

只需要分享前端地址：
```
https://xxxx-xxxx-xxxx.ngrok.io
```

他们无需安装任何工具，直接在浏览器打开即可。

### 登录

默认账户：
- **用户名**: admin
- **密码**: changeme123

## 关键特性

| 特性 | 说明 |
|-----|------|
| **速度快** | ngrok 在全球有多个数据中心，连接快速 |
| **无需配置** | 一键启动，无需配置防火墙或域名 |
| **临时性** | 每次启动时都会生成新的公网 URL |
| **安全** | HTTPS 加密，ngrok 的 IP 限制功能可增强安全 |
| **实时性** | 前端代码热更新（HMR）保留，后端修改实时生效 |

## 常见问题

### Q1: 演示时网络卡顿怎么办？

**解决方案：**
1. 检查本地网络连接
2. 在 tunnel.sh 中添加速率限制
3. 关闭浏览器其他标签页
4. 如果是国际演示，ngrok 可能有延迟，可考虑企业版

### Q2: 如何提高安全性（限制访问）？

**方案 1：IP 白名单**
```bash
ngrok http --authtoken TOKEN --allow-user-agent "^(?!.*bot)" 5173
```

**方案 2：密码保护**
在启动码中添加基本认证：
```bash
ngrok http --auth "username:password" 5173
```

### Q3: 穿透 URL 会过期吗？

- **免费账户**：URL 在每次重启 ngrok 时更改
- **企业版**：可以使用固定的子域名

### Q4: 如何查看实时连接和活动？

ngrok 提供实时监控面板：
- 打开浏览器访问：http://127.0.0.1:4040
- 查看所有穿透隧道状态和请求日志

### Q5: 演示完后，如何停止穿透？

```bash
# 按 Ctrl+C 停止 tunnel.sh
# 本地服务可继续运行
```

## 性能优化建议

### 1. 减小前端体积
```bash
# 在 frontend/vite.config.js 中启用压缩
npm run build  # 生产构建
```

### 2. 限制 API 响应大小
在后端 API 中添加分页限制

### 3. 使用缓存
```javascript
// 在前端添加缓存策略
localStorage.setItem('data', JSON.stringify(data))
```

## 高级配置

### 自定义 ngrok 配置

编辑 `~/.ngrok2/ngrok.yml`：

```yaml
authtoken: your_token_here

tunnels:
  frontend:
    proto: http
    addr: 5173
    
  backend:
    proto: http
    addr: 8001
    bind_tls: true    # 强制 HTTPS
```

### 监控带宽使用

```bash
# 在 tunnel.sh 中启用详细日志
ngrok http --log stdout 5173
```

## 演示最佳实践

### 前 5 分钟
1. ✅ 测试穿透是否正常工作
2. ✅ 确认本地数据库已初始化
3. ✅ 清空浏览器缓存
4. ✅ 在另一个浏览器/设备上测试链接

### 演示中
1. 💡 提前准备演示数据
2. 💡 有备份方案（如离线截图）
3. 💡 使用有线网络而非 WiFi
4. 💡 关闭 VPN（可能会影响穿透性能）

### 演示后
1. 🛑 使用 Ctrl+C 停止 ngrok
2. 🛑 清理数据库（可选）
3. 🛑 复位密码（如果修改过）

## 成本

| 服务 | 免费额度 | 成本 |
|-----|---------|------|
| ngrok 穿透 | 40 连接/小时 | $0（免费用户） |
| ngrok Pro | 无限制 | $5/月 起 |
| ngrok 企业版 | 固定 URL | 联系销售 |

## 下一步

演示成功后，如需长期对外服务，建议：

1. **短期**（1-2 周）：继续用 ngrok Free + VPS
2. **中期**（1-3 月）：升级 ngrok Pro 或自建 VPS + ngrok
3. **长期**：使用方案 3（Docker + 云服务器），详见 README.md

---

需要帮助？运行：
```bash
bash tunnel.sh --help
```
