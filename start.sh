#!/bin/bash
# 建筑工人信用风险管理系统 - 本地部署脚本（无 Docker）
# 使用方式: bash start.sh

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$ROOT_DIR/data"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
VENV_DIR="$BACKEND_DIR/.venv"
export BACKEND_PORT="${BACKEND_PORT:-8001}"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

cleanup() {
    info "正在停止服务..."
    [ -n "$BACKEND_PID" ] && kill "$BACKEND_PID" 2>/dev/null
    [ -n "$FRONTEND_PID" ] && kill "$FRONTEND_PID" 2>/dev/null
    wait 2>/dev/null
    info "服务已停止"
}
trap cleanup EXIT INT TERM

# ========== 环境检查 ==========
info "检查运行环境..."

# 查找 Python 3.10+
PYTHON=""
for cmd in python3.13 python3.12 python3.11 python3.10; do
    if command -v "$cmd" >/dev/null 2>&1; then
        PYTHON="$(command -v "$cmd")"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    # 回退到 python3 并检查版本
    if command -v python3 >/dev/null 2>&1; then
        PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
        if [ "$PY_MINOR" -ge 10 ]; then
            PYTHON="$(command -v python3)"
        fi
    fi
fi
[ -z "$PYTHON" ] && error "未找到 Python 3.10+，请先安装（brew install python@3.10）"

command -v node >/dev/null 2>&1 || error "未找到 node，请先安装 Node.js 18+"
command -v npm >/dev/null 2>&1  || error "未找到 npm，请先安装 Node.js 18+"

PYTHON_VERSION=$("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
info "Python $PYTHON_VERSION ($PYTHON) | Node $(node -v)"

# ========== 数据目录 ==========
mkdir -p "$DATA_DIR"

# ========== 后端设置 ==========
info "配置后端..."

if [ ! -d "$VENV_DIR" ]; then
    info "创建 Python 虚拟环境..."
    "$PYTHON" -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

info "安装后端依赖..."
pip install -q -r "$BACKEND_DIR/requirements.txt"

# 设置环境变量
export DATABASE_URL="sqlite+aiosqlite:///$DATA_DIR/credit_mgmt.db"
export JWT_SECRET_KEY="${JWT_SECRET_KEY:-$(python3 -c 'import secrets; print(secrets.token_hex(32))')}"

# 初始化数据库和种子数据
info "初始化数据库..."
cd "$BACKEND_DIR"
python3 seed.py

# 启动后端
info "启动后端服务 (http://localhost:$BACKEND_PORT)..."
uvicorn app.main:app --host 0.0.0.0 --port "$BACKEND_PORT" &
BACKEND_PID=$!

# ========== 前端设置 ==========
info "配置前端..."
cd "$FRONTEND_DIR"

if [ ! -d "node_modules" ]; then
    info "安装前端依赖..."
    npm install
fi

# 启动前端开发服务器（自带代理到后端 8000 端口）
info "启动前端服务 (http://localhost:5173)..."
npx vite --host 0.0.0.0 &
FRONTEND_PID=$!

# ========== 就绪 ==========
sleep 2
echo ""
info "========================================="
info " 系统已启动！"
info " 前端地址:  http://localhost:5173"
info " 后端API:   http://localhost:$BACKEND_PORT"
info " API文档:   http://localhost:$BACKEND_PORT/docs"
info " 默认账户:  admin / changeme123"
info " 按 Ctrl+C 停止所有服务"
info "========================================="
echo ""

wait
