#!/bin/bash
# 信用风险管理系统 - 临时演示穿透脚本
# 使用 ngrok 将本地服务暴露到公网

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
blue()  { echo -e "${BLUE}[LINK]${NC} $1"; }

# ========== 检查环境 ==========
info "检查环境..."

# 检查本地服务是否运行
check_service() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        info "$name 已在 localhost:$port 运行"
        return 0
    else
        warn "$name 未在 localhost:$port 运行"
        info "请先运行: bash start.sh"
        return 1
    fi
}

# 检查 ngrok 安装
if ! command -v ngrok &> /dev/null; then
    error "未找到 ngrok，请先安装:"
    echo "  macOS: brew install ngrok"
    echo "  其他系统: https://ngrok.com/download"
fi

info "ngrok 版本: $(ngrok --version | head -1)"

# ========== 检查本地服务 ==========
echo ""
info "检查本地服务..."
FRONTEND_OK=0
BACKEND_OK=0

check_service 5173 "前端" && FRONTEND_OK=1 || true
check_service 8001 "后端" && BACKEND_OK=1 || true

if [ "$FRONTEND_OK" -eq 0 ] || [ "$BACKEND_OK" -eq 0 ]; then
    warn "部分服务未运行，请确保已启动: bash start.sh"
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# ========== 检查 ngrok 认证 ==========
if [ ! -f ~/.ngrok2/ngrok.yml ] || ! grep -q "authtoken" ~/.ngrok2/ngrok.yml 2>/dev/null; then
    error "ngrok 未配置认证令牌"
    echo ""
    echo "获取令牌步骤:"
    echo "  1. 访问: https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "  2. 注册/登录并复制 authtoken"
    echo "  3. 运行配置: ngrok config add-authtoken YOUR_TOKEN"
    exit 1
fi

# ========== 启动穿透 ==========
echo ""
info "========================================="
info "     启动公网穿透..."
info "========================================="
echo ""

# 启动 ngrok（只穿透前端，前端会通过代理访问本地后端）
info "启动前端穿透 (localhost:5173)..."
ngrok http 5173 --log=stdout > /tmp/ngrok_frontend_$$.log 2>&1 &
FRONTEND_PID=$!

info "ngrok 已启动 (前端 PID: $FRONTEND_PID)"

# ========== 等待并获取穿透地址 ==========
sleep 4

info "获取穿透地址..."
# 重试逻辑，等待穿透就绪
RETRY=0
MAX_RETRY=10
while [ $RETRY -lt $MAX_RETRY ]; do
    NGROK_API="http://127.0.0.1:4040/api/tunnels"
    
    # 检查 ngrok web 界面是否可访问
    if curl -s --max-time 2 "http://127.0.0.1:4040" > /dev/null 2>&1; then
        info "ngrok web 界面可访问"
    else
        warn "ngrok web 界面不可访问，等待..."
    fi
    
    TUNNEL_INFO=$(curl -s "$NGROK_API" 2>/dev/null || echo "")
    
    if [ -n "$TUNNEL_INFO" ]; then
        break
    fi
    
    RETRY=$((RETRY + 1))
    warn "等待 ngrok 就绪... ($RETRY/$MAX_RETRY)"
    sleep 2
done

if [ -z "$TUNNEL_INFO" ]; then
    error "无法连接 ngrok API，请检查 ngrok 是否正确启动"
fi

# 解析穿透 URL（多种格式兼容）
# 尝试不同的 JSON 解析方式
FRONTEND_URL=""

# 方法 1: 标准格式
if [ -z "$FRONTEND_URL" ]; then
    FRONTEND_URL=$(echo "$TUNNEL_INFO" | grep -o '"public_url":"https://[^"]*"' | head -1 | sed 's/"public_url":"//' | sed 's/"$//')
fi

# 方法 2: 简化格式
if [ -z "$FRONTEND_URL" ]; then
    FRONTEND_URL=$(echo "$TUNNEL_INFO" | grep -o 'https://[^"]*\.ngrok[^"]*' | head -1)
fi

# 方法 3: 使用 jq 如果可用
if [ -z "$FRONTEND_URL" ] && command -v jq &> /dev/null; then
    FRONTEND_URL=$(echo "$TUNNEL_INFO" | jq -r '.tunnels[0].public_url' 2>/dev/null)
fi

if [ -z "$FRONTEND_URL" ]; then
    error "无法获取穿透地址，请检查 ngrok 运行状态"
fi

# ========== 展示访问信息 ==========
echo ""
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 临时演示环境已启动！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

blue "前端访问地址: $FRONTEND_URL"
blue "后端 API 地址: http://localhost:8001 (本地代理)"
blue "API 文档: http://localhost:8001/docs (本地访问)"

echo ""
echo -e "${YELLOW}默认登录账户:${NC}"
echo "  用户名: admin"
echo "  密码: changeme123"
echo ""

echo -e "${YELLOW}演示链接:${NC}"
echo "  点击访问: $FRONTEND_URL"
echo ""

echo -e "${YELLOW}复制给别人的链接:${NC}"
echo "  $FRONTEND_URL"
echo ""

echo -e "${BLUE}说明:${NC}"
echo "  • 外部用户通过 $FRONTEND_URL 访问前端"
echo "  • 前端会自动代理 API 请求到本地后端"
echo "  • API 文档可在本地浏览器访问 http://localhost:8001/docs"

# ========== 清理函数 ==========
cleanup() {
    echo ""
    warn "正在停止穿透..."
    kill $FRONTEND_PID 2>/dev/null || true
    rm -f /tmp/ngrok_frontend_$$.log
    sleep 1
    info "穿透已停止"
    echo "本地服务仍在运行，可继续使用 http://localhost:5173"
}

trap cleanup EXIT INT TERM

# ========== 监控模式 ==========
echo -e "${YELLOW}实时监控穿透状态 (按 Ctrl+C 停止):${NC}"
echo ""

# 定期刷新显示穿透状态
while true; do
    TUNNEL_STATUS=$(curl -s "http://127.0.0.1:4040/api/tunnels" 2>/dev/null | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ "$TUNNEL_STATUS" != "online" ] && [ -n "$TUNNEL_STATUS" ]; then
        warn "穿透状态: $TUNNEL_STATUS"
    fi
    
    sleep 5
done
