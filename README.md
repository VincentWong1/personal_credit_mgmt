"# 建筑工人信用风险管理系统 - 实施方案

## Context

为甲方搭建一个面向外部用户的网站服务，用于维护、管理和查询公司关联建筑工人的信用风险信息。系统需支持三种角色（管理员、运维人员、普通用户），提供工人信息录入、风险事件管理和查询功能。

## 技术栈

| 层级 | 技术选型 | 说明 |
|------|---------|------|
| 后端 | FastAPI + SQLAlchemy 2.0 (async) | 自动生成 API 文档，类型安全，性能好 |
| 前端 | Vue 3 + Vite + Element Plus | 中文企业级 UI 组件库，适合管理后台 |
| 数据库 | SQLite（初期） | 零配置，可平滑迁移至 PostgreSQL |
| 认证 | JWT (access + refresh token) | python-jose + passlib/bcrypt |
| 部署 | Docker Compose (Nginx + Uvicorn) | 一键部署 |

## 数据库设计

### users 表（系统用户）
| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK | 自增主键 |
| username | VARCHAR(50) | UNIQUE, NOT NULL | 登录名 |
| hashed_password | VARCHAR(128) | NOT NULL | bcrypt 哈希 |
| display_name | VARCHAR(50) | NOT NULL | 显示名称 |
| role | VARCHAR(20) | NOT NULL, DEFAULT 'user' | admin / operator / user |
| is_active | BOOLEAN | DEFAULT TRUE | 软删除标记 |
| created_at / updated_at | DATETIME | | 时间戳 |

### workers 表（建筑工人）
| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK | 自增主键 |
| id_card_number | VARCHAR(18) | UNIQUE, NOT NULL, INDEX | 身份证号（唯一标识） |
| name | VARCHAR(50) | NOT NULL, INDEX | 姓名 |
| gender | VARCHAR(4) | NOT NULL | male/female，前端映射为中文 |
| created_by | INTEGER | FK -> users.id | 创建人 |
| created_at / updated_at | DATETIME | | 时间戳 |

### risk_events 表（风险事件）
| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK | 自增主键 |
| worker_id | INTEGER | FK -> workers.id, INDEX | 关联工人 |
| event_date | DATE | NOT NULL, INDEX | 事件日期（用于倒排） |
| risk_level | VARCHAR(20) | NOT NULL | low / medium / high / critical |
| category | VARCHAR(50) | NOT NULL | 事件类别 |
| description | TEXT | | 事件详细描述 |
| company_id | INTEGER | FK -> companies.id | 关联单位 |
| project_id | INTEGER | FK -> projects.id | 关联项目 |
| created_by | INTEGER | FK -> users.id | 录入人 |
| created_at / updated_at | DATETIME | | 时间戳 |

### companies 表（关联单位）
| 字段 | 类型 | 约束 |
|------|------|------|
| id | INTEGER | PK |
| name | VARCHAR(200) | UNIQUE, NOT NULL |

### projects 表（关联项目）
| 字段 | 类型 | 约束 |
|------|------|------|
| id | INTEGER | PK |
| name | VARCHAR(200) | NOT NULL |
| company_id | INTEGER | FK -> companies.id |

## API 设计（RESTful，前缀 `/api/v1`）

### 认证
- `POST /auth/login` — 登录，返回 JWT token
- `POST /auth/refresh` — 刷新 token
- `GET /auth/me` — 获取当前用户信息
- `PUT /auth/password` — 修改密码

### 用户管理（仅管理员）
- `GET/POST /users` — 列表 / 创建用户
- `GET/PUT/DELETE /users/{id}` — 查看 / 编辑 / 停用用户

### 工人管理
- `GET /workers?q=xxx&page=1` — 搜索工人（姓名或身份证号），所有登录用户可用
- `POST /workers` — 新增工人（管理员 / 运维）
- `GET /workers/{id}` — 工人详情（含风险事件按日期倒排）
- `PUT /workers/{id}` — 编辑工人（管理员 / 运维）
- `DELETE /workers/{id}` — 删除工人（仅管理员）

### 风险事件
- `GET /workers/{id}/events` — 某工人的风险事件列表（按 event_date DESC）
- `POST /workers/{id}/events` — 新增风险事件（管理员 / 运维）
- `PUT /events/{id}` — 编辑事件（管理员 / 运维）
- `DELETE /events/{id}` — 删除事件（仅管理员）

### 辅助
- `GET/POST /companies` — 单位列表 / 新增
- `GET/POST /projects` — 项目列表 / 新增
- `GET /stats/overview` — 首页统计数据

## 前端页面结构

```
/login                    — 登录页
/                         — 首页仪表盘（统计概览）
/workers                  — 工人列表（搜索 + 分页表格）
/workers/:id              — 工人详情（基本信息 + 风险事件时间线）
/workers/new              — 新增工人（管理员/运维可见）
/workers/:id/edit         — 编辑工人
/workers/:id/events/new   — 新增风险事件
/events/:id/edit          — 编辑风险事件
/users                    — 用户管理（仅管理员可见）
/profile                  — 个人设置（改密码）
```

### 核心组件
- `AppLayout.vue` — 侧边栏 + 顶栏 + 内容区
- `RiskLevelTag.vue` — 颜色标签（绿/黄/红/深红）
- `IdCardInput.vue` — 身份证号输入框（含校验 + 性别自动识别）
- `SearchBar.vue` — 搜索框（防抖，placeholder: \"输入姓名或身份证号搜索\"）

## 权限控制

| 操作 | admin | operator | user |
|------|-------|----------|------|
| 查询工人/事件 | ✓ | ✓ | ✓ |
| 新增/编辑工人和事件 | ✓ | ✓ | ✗ |
| 删除工人/事件 | ✓ | ✗ | ✗ |
| 管理用户/赋权 | ✓ | ✗ | ✗ |

后端通过 FastAPI 依赖注入实现：`get_current_user` / `require_operator` / `require_admin`

## 项目目录结构

```
personal_credit_mgmt/
├── docker-compose.yml
├── .env.example
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── alembic.ini
│   ├── alembic/versions/
│   ├── seed.py                    # 初始化默认管理员账户
│   └── app/
│       ├── main.py                # FastAPI 入口，CORS，路由挂载
│       ├── config.py              # 环境变量配置
│       ├── database.py            # 异步数据库引擎
│       ├── models/                # SQLAlchemy 模型
│       ├── schemas/               # Pydantic 请求/响应模型
│       ├── api/
│       │   ├── deps.py            # 认证/权限依赖注入
│       │   └── v1/                # 各资源路由
│       ├── services/              # 业务逻辑层
│       └── utils/
│           ├── id_card.py         # 身份证号校验 + 性别提取
│           └── pagination.py      # 分页工具
└── frontend/
    ├── Dockerfile
    ├── nginx.conf                 # Nginx 反向代理 + SPA fallback
    ├── package.json
    ├── vite.config.js
    └── src/
        ├── main.js
        ├── router/index.js        # 路由 + 权限守卫
        ├── stores/auth.js         # Pinia 认证状态
        ├── api/                   # Axios 封装 + 各模块 API
        ├── layouts/AppLayout.vue
        ├── views/                 # 各页面组件
        ├── components/            # 通用组件
        └── utils/                 # 身份证校验等工具函数
```

## 部署方案

使用 Docker Compose 一键部署：
- **backend 容器**：Python 3.11 + Uvicorn，端口 8000
- **frontend 容器**：Nginx 托管 Vue 构建产物，端口 80，反向代理 `/api/` 到 backend
- SQLite 数据文件通过 Docker volume 持久化到 `./data/` 目录
- 首次启动自动创建默认管理员账户（admin / changeme123）

```bash
export JWT_SECRET_KEY=$(openssl rand -hex 32)
docker compose up -d --build
```

## 实施步骤

1. **后端基础**：项目初始化 → 数据库模型 → Alembic 迁移 → 认证模块 → 种子数据
2. **后端 CRUD**：Pydantic schema → 工人/事件/单位/项目 API → 用户管理 API → 统计 API
3. **前端基础**：Vue 项目初始化 → Element Plus 配置 → Axios 封装 → 路由 + 权限守卫 → 布局组件
4. **前端页面**：登录页 → 工人列表/搜索 → 工人详情 → 表单页面 → 用户管理 → 仪表盘
5. **部署集成**：Dockerfile → docker-compose.yml → Nginx 配置 → 端到端测试

## 验证方式

1. `docker compose up -d --build` 启动全部服务
2. 浏览器访问 `http://localhost` 看到登录页
3. 使用默认管理员账户登录，验证仪表盘展示
4. 创建运维用户并赋权，用运维账户登录测试新增工人/事件
5. 创建普通用户，验证只能搜索查询，不能新增/编辑
6. 通过身份证号和姓名搜索工人，确认风险事件按日期倒排展示
7. 访问 `http://localhost:8000/docs` 查看自动生成的 API 文档

## Quick Start

### 本地单机部署的使用方式：

```bash
bash start.sh
```

脚本会自动完成：
1. 检查 Python 和 Node.js 环境
2. 创建虚拟环境并安装后端依赖
3. 初始化数据库 + 种子数据（默认管理员 admin / changeme123）
4. 启动后端 (`:8000`)
5. 安装前端依赖并启动 Vite 开发服务器 (`:5173`，自动代理 `/api` 到后端)

启动后访问 `http://localhost:5173`，`Ctrl+C` 停止所有服务。

### Docker 部署的使用方式：

```
