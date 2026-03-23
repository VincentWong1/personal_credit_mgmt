#!/bin/bash

echo "🚀 开始测试 Docker 部署..."

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查 Docker 是否运行
echo -e "\n${YELLOW}[1/6]${NC} 检查 Docker 状态..."
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker 未运行，请先启动 Docker${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker 运行正常${NC}"

# 2. 停止旧容器
echo -e "\n${YELLOW}[2/6]${NC} 停止旧容器..."
docker-compose down
echo -e "${GREEN}✓ 旧容器已停止${NC}"

# 3. 构建并启动服务
echo -e "\n${YELLOW}[3/6]${NC} 构建并启动服务（这可能需要几分钟）..."
docker-compose up -d --build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 服务启动失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 服务启动成功${NC}"

# 4. 等待服务就绪
echo -e "\n${YELLOW}[4/6]${NC} 等待服务就绪..."
sleep 10

# 5. 检查容器状态
echo -e "\n${YELLOW}[5/6]${NC} 检查容器状态..."
docker-compose ps

# 6. 测试服务
echo -e "\n${YELLOW}[6/6]${NC} 测试服务..."

# 测试后端健康检查
echo -e "\n测试后端 API..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health)
if [ "$BACKEND_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ 后端 API 正常 (http://localhost:8000/api/health)${NC}"
else
    echo -e "${RED}❌ 后端 API 异常 (HTTP $BACKEND_RESPONSE)${NC}"
    echo "查看后端日志："
    docker-compose logs --tail=20 backend
fi

# 测试前端
echo -e "\n测试前端..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ 前端正常 (http://localhost)${NC}"
else
    echo -e "${RED}❌ 前端异常 (HTTP $FRONTEND_RESPONSE)${NC}"
    echo "查看前端日志："
    docker-compose logs --tail=20 frontend
fi

# 测试通过 nginx 访问后端
echo -e "\n测试 Nginx 反向代理..."
PROXY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health)
if [ "$PROXY_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Nginx 反向代理正常 (http://localhost/api/health)${NC}"
else
    echo -e "${RED}❌ Nginx 反向代理异常 (HTTP $PROXY_RESPONSE)${NC}"
fi

# 总结
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Docker 部署测试完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n📝 访问信息："
echo -e "  • 前端：http://localhost"
echo -e "  • 后端 API：http://localhost:8000/api/"
echo -e "  • API 文档：http://localhost:8000/docs"
echo -e "  • 默认账户：admin / changeme123"

echo -e "\n🌐 ngrok 使用方法："
echo -e "  1. 安装 ngrok：https://ngrok.com/download"
echo -e "  2. 认证：ngrok config add-authtoken YOUR_TOKEN"
echo -e "  3. 启动隧道：ngrok http 80"
echo -e "  4. 使用 ngrok 提供的 URL 访问服务"

echo -e "\n📋 常用命令："
echo -e "  • 查看日志：docker-compose logs -f"
echo -e "  • 重启服务：docker-compose restart"
echo -e "  • 停止服务：docker-compose down"
