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

# 创建临时配置文件
NGROK_CONFIG="/tmp/ngrok_demo_$$.yml"
cat > "$NGROK_CONFIG" <<'EOF'
version: "2"
tunnels:
  frontend:
    proto: http
    addr: 5173
    bind_tls: true
    inspect: false
    
  backend:
    proto: http
    addr: 8001
    bind_tls: true
    inspect: false

log_level: info
EOF

# 启动 ngrok
ngrok start -c "$NGROK_CONFIG" frontend backend &
NGROK_PID=$!

info "ngrok 已启动 (PID: $NGROK_PID)"

# ========== 等待并获取穿透地址 ==========
sleep 3

info "获取穿透地址..."
NGROK_API="http://127.0.0.1:4040/api/tunnels"
TUNNEL_INFO=$(curl -s "$NGROK_API")

# 解析穿透 URL
FRONTEND_URL=$(echo "$TUNNEL_INFO" | grep -o '"https://[^"]*"' | head -1 | tr -d '"')
BACKEND_URL=$(echo "$TUNNEL_INFO" | grep -o '"https://[^"]*"' | tail -1 | tr -d '"')

if [ -z "$FRONTEND_URL" ] || [ -z "$BACKEND_URL" ]; then
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
blue "后端 API 基础: $BACKEND_URL"
blue "API 文档: $BACKEND_URL/docs"

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

# ========== 清理函数 ==========
cleanup() {
    echo ""
    warn "正在停止穿透..."
    kill $NGROK_PID 2>/dev/null || true
    rm -f "$NGROK_CONFIG"
    info "穿透已停止"
    echo "本地服务仍在运行，可继续使用 http://localhost:5173"
}

trap cleanup EXIT INT TERM

# ========== 监控模式 ==========
echo -e "${YELLOW}实时监控穿透状态 (按 Ctrl+C 停止):${NC}"
echo ""

# 定期刷新显示穿透状态
while true; do
    TUNNEL_STATUS=$(curl -s "$NGROK_API" 2>/dev/null | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ "$TUNNEL_STATUS" != "online" ]; then
        warn "穿透状态: $TUNNEL_STATUS"
    fi
    
    # 显示实时连接数（如果需要可配置显示）
    # echo "✓ 穿透已连接"
    
    sleep 5
done
