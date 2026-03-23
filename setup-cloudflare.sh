#!/bin/bash

# Cloudflare Tunnel 自动配置脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Cloudflare Tunnel 配置向导${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查 cloudflared 是否安装
echo -e "\n${YELLOW}[1/6]${NC} 检查 cloudflared 安装..."
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}❌ cloudflared 未安装${NC}"
    echo -e "\n请先安装 cloudflared："
    echo -e "  macOS:   ${GREEN}brew install cloudflare/cloudflare/cloudflared${NC}"
    echo -e "  Linux:   ${GREEN}wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && sudo dpkg -i cloudflared-linux-amd64.deb${NC}"
    echo -e "  Windows: ${GREEN}https://github.com/cloudflare/cloudflared/releases/latest${NC}"
    exit 1
fi
echo -e "${GREEN}✓ cloudflared 已安装${NC}"

# 登录 Cloudflare
echo -e "\n${YELLOW}[2/6]${NC} 登录 Cloudflare..."
echo -e "即将打开浏览器，请选择你的域名并授权..."
read -p "按 Enter 继续..."
cloudflared tunnel login

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 登录失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 登录成功${NC}"

# 创建隧道
echo -e "\n${YELLOW}[3/6]${NC} 创建隧道..."
TUNNEL_NAME="credit-mgmt-$(date +%s)"
echo -e "隧道名称: ${GREEN}$TUNNEL_NAME${NC}"

TUNNEL_OUTPUT=$(cloudflared tunnel create $TUNNEL_NAME 2>&1)
TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1)

if [ -z "$TUNNEL_ID" ]; then
    echo -e "${RED}❌ 创建隧道失败${NC}"
    echo "$TUNNEL_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✓ 隧道创建成功${NC}"
echo -e "Tunnel ID: ${GREEN}$TUNNEL_ID${NC}"

# 输入域名
echo -e "\n${YELLOW}[4/6]${NC} 配置域名..."
read -p "请输入你的域名（例如：demo.yourdomain.com）: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ 域名不能为空${NC}"
    exit 1
fi

# 创建 cloudflared 目录
mkdir -p cloudflared

# 复制凭证文件
echo -e "\n${YELLOW}[5/6]${NC} 配置凭证..."
CRED_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"

if [ ! -f "$CRED_FILE" ]; then
    echo -e "${RED}❌ 凭证文件不存在: $CRED_FILE${NC}"
    exit 1
fi

cp "$CRED_FILE" cloudflared/credentials.json
echo -e "${GREEN}✓ 凭证文件已复制${NC}"

# 生成配置文件
cat > cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/credentials.json

ingress:
  - hostname: $DOMAIN
    service: http://frontend:80
  - service: http_status:404
EOF

echo -e "${GREEN}✓ 配置文件已生成${NC}"

# 配置 DNS
echo -e "\n${YELLOW}[6/6]${NC} 配置 DNS..."
cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠ DNS 配置失败，请手动在 Cloudflare Dashboard 添加 CNAME 记录${NC}"
    echo -e "  名称: ${GREEN}$DOMAIN${NC}"
    echo -e "  目标: ${GREEN}$TUNNEL_ID.cfargotunnel.com${NC}"
else
    echo -e "${GREEN}✓ DNS 配置成功${NC}"
fi

# 完成
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Cloudflare Tunnel 配置完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n📝 配置信息："
echo -e "  • 隧道名称: ${GREEN}$TUNNEL_NAME${NC}"
echo -e "  • Tunnel ID: ${GREEN}$TUNNEL_ID${NC}"
echo -e "  • 域名: ${GREEN}https://$DOMAIN${NC}"

echo -e "\n🚀 启动服务："
echo -e "  ${GREEN}docker-compose --profile cloudflare up -d --build${NC}"

echo -e "\n📋 查看日志："
echo -e "  ${GREEN}docker-compose logs -f cloudflared${NC}"

echo -e "\n🌐 访问服务："
echo -e "  ${GREEN}https://$DOMAIN${NC}"

echo -e "\n💡 提示："
echo -e "  • DNS 传播可能需要几分钟"
echo -e "  • 默认账户：admin / changeme123"
echo -e "  • 详细文档：CLOUDFLARE_SETUP.md"
