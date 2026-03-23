<template>
  <el-container class="app-layout">
    <!-- PC 侧边栏 -->
    <el-aside v-if="!isMobile" width="220px" class="app-aside">
      <div class="logo">
        <h3>信用风险管理</h3>
      </div>
      <el-menu
        :default-active="activeMenu"
        router
        background-color="#304156"
        text-color="#bfcbd9"
        active-text-color="#409EFF"
      >
        <el-menu-item index="/">
          <el-icon><DataAnalysis /></el-icon>
          <span>仪表盘</span>
        </el-menu-item>
        <el-menu-item index="/workers">
          <el-icon><User /></el-icon>
          <span>工人管理</span>
        </el-menu-item>
        <el-menu-item index="/events">
          <el-icon><Warning /></el-icon>
          <span>风险事件</span>
        </el-menu-item>
        <el-menu-item v-if="auth.isAdmin" index="/users">
          <el-icon><Setting /></el-icon>
          <span>用户管理</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <!-- 移动端抽屉 -->
    <el-drawer
      v-if="isMobile"
      v-model="drawerOpen"
      direction="ltr"
      :size="240"
      :with-header="false"
    >
      <div class="drawer-aside">
        <div class="logo">
          <h3>信用风险管理</h3>
        </div>
        <el-menu
          :default-active="activeMenu"
          background-color="#304156"
          text-color="#bfcbd9"
          active-text-color="#409EFF"
          @select="handleMenuSelect"
        >
          <el-menu-item index="/">
            <el-icon><DataAnalysis /></el-icon>
            <span>仪表盘</span>
          </el-menu-item>
          <el-menu-item index="/workers">
            <el-icon><User /></el-icon>
            <span>工人管理</span>
          </el-menu-item>
          <el-menu-item index="/events">
            <el-icon><Warning /></el-icon>
            <span>风险事件</span>
          </el-menu-item>
          <el-menu-item v-if="auth.isAdmin" index="/users">
            <el-icon><Setting /></el-icon>
            <span>用户管理</span>
          </el-menu-item>
        </el-menu>
      </div>
    </el-drawer>

    <el-container>
      <el-header class="app-header">
        <div class="header-left">
          <el-button v-if="isMobile" text @click="drawerOpen = true" class="menu-btn">
            <el-icon :size="20"><Fold /></el-icon>
          </el-button>
          <span class="header-title">{{ isMobile ? '信用风险管理' : '建筑工人信用风险管理系统' }}</span>
        </div>
        <div class="header-right">
          <span v-if="!isMobile" class="user-info">{{ auth.user?.display_name }}</span>
          <el-tag size="small" :type="roleTagType">{{ roleLabel }}</el-tag>
          <el-dropdown @command="handleCommand">
            <el-button text>
              <el-icon><ArrowDown /></el-icon>
            </el-button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人设置</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      <el-main class="app-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { DataAnalysis, User, Setting, ArrowDown, Warning, Fold } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const drawerOpen = ref(false)

const windowWidth = ref(window.innerWidth)
const isMobile = computed(() => windowWidth.value < 768)

function onResize() {
  windowWidth.value = window.innerWidth
}
onMounted(() => window.addEventListener('resize', onResize))
onUnmounted(() => window.removeEventListener('resize', onResize))

const activeMenu = computed(() => {
  const path = route.path
  if (path.startsWith('/workers')) return '/workers'
  if (path.startsWith('/events')) return '/events'
  if (path.startsWith('/users')) return '/users'
  return '/'
})

const roleMap = { admin: '管理员', operator: '运维', user: '普通用户' }
const roleLabel = computed(() => roleMap[auth.user?.role] || '未知')
const roleTagType = computed(() => {
  const m = { admin: 'danger', operator: 'warning', user: '' }
  return m[auth.user?.role] || ''
})

function handleMenuSelect(index) {
  drawerOpen.value = false
  router.push(index)
}

function handleCommand(cmd) {
  if (cmd === 'logout') {
    auth.logout()
    router.push('/login')
  } else if (cmd === 'profile') {
    router.push('/profile')
  }
}
</script>

<style scoped>
.app-layout {
  height: 100vh;
}
.app-aside {
  background-color: #304156;
  overflow-y: auto;
}
.drawer-aside {
  background-color: #304156;
  height: 100%;
}
.logo {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}
.logo h3 {
  margin: 0;
  font-size: 16px;
}
.app-header {
  background: #fff;
  border-bottom: 1px solid #e6e6e6;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 12px;
}
.header-left {
  display: flex;
  align-items: center;
  gap: 4px;
  min-width: 0;
}
.menu-btn {
  padding: 4px;
}
.header-title {
  font-size: 16px;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}
.user-info {
  font-size: 14px;
  color: #606266;
}
.app-main {
  background: #f0f2f5;
  min-height: 0;
  overflow-y: auto;
}

@media (max-width: 767px) {
  .app-main {
    padding: 12px;
  }
  .header-title {
    font-size: 14px;
  }
}
</style>
