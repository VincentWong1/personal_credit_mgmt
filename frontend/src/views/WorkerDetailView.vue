<template>
  <div v-loading="loading">
    <div class="page-header">
      <el-page-header @back="$router.push('/workers')" title="返回列表" :content="worker?.name" />
      <div v-if="auth.isOperator">
        <el-button type="primary" @click="$router.push(`/workers/${workerId}/events/new`)">新增风险事件</el-button>
      </div>
    </div>

    <el-card v-if="worker" style="margin-bottom: 20px">
      <template #header>基本信息</template>
      <el-descriptions :column="isMobile ? 1 : 3" border>
        <el-descriptions-item label="姓名">{{ worker.name }}</el-descriptions-item>
        <el-descriptions-item label="性别">{{ worker.gender === 'male' ? '男' : '女' }}</el-descriptions-item>
        <el-descriptions-item label="身份证号">{{ worker.id_card_number }}</el-descriptions-item>
        <el-descriptions-item label="风险事件数">
          <el-tag v-if="worker.risk_event_count > 0" type="danger">{{ worker.risk_event_count }}</el-tag>
          <span v-else>0</span>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ formatDate(worker.created_at) }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card v-if="worker">
      <template #header>
        <span>风险事件时间线</span>
      </template>
      <el-timeline v-if="events.length">
        <el-timeline-item
          v-for="event in events"
          :key="event.id"
          :timestamp="event.event_date"
          placement="top"
          :color="levelColor(event.risk_level)"
        >
          <el-card shadow="hover" class="event-card">
            <div class="event-header">
              <RiskLevelTag :level="event.risk_level" />
              <el-tag type="info" size="small">{{ event.category }}</el-tag>
              <span v-if="event.company_name" class="event-meta">{{ event.company_name }}</span>
              <span v-if="event.project_name" class="event-meta">/ {{ event.project_name }}</span>
            </div>
            <p v-if="event.description" class="event-desc">{{ event.description }}</p>
            <div class="event-actions" v-if="auth.isOperator">
              <el-button link type="primary" size="small" @click="$router.push(`/events/${event.id}/edit`)">编辑</el-button>
              <el-popconfirm v-if="auth.isAdmin" title="确定删除该事件？" @confirm="handleDeleteEvent(event.id)">
                <template #reference>
                  <el-button link type="danger" size="small">删除</el-button>
                </template>
              </el-popconfirm>
            </div>
          </el-card>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无风险事件" />
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { workersApi } from '../api/workers'
import { eventsApi } from '../api/events'
import { ElMessage } from 'element-plus'
import RiskLevelTag from '../components/RiskLevelTag.vue'

const route = useRoute()
const auth = useAuthStore()
const workerId = route.params.id
const windowWidth = ref(window.innerWidth)
const isMobile = computed(() => windowWidth.value < 768)
function onResize() { windowWidth.value = window.innerWidth }
const worker = ref(null)
const events = ref([])
const loading = ref(false)

const levelColors = { low: '#67c23a', medium: '#e6a23c', high: '#f56c6c', critical: '#8b0000' }

function levelColor(level) {
  return levelColors[level] || '#909399'
}

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleString('zh-CN')
}

async function loadWorker() {
  loading.value = true
  try {
    const res = await workersApi.get(workerId)
    worker.value = res
    events.value = res.risk_events || []
  } catch {
    ElMessage.error('加载工人信息失败')
  } finally {
    loading.value = false
  }
}

async function handleDeleteEvent(eventId) {
  try {
    await eventsApi.delete(eventId)
    ElMessage.success('事件已删除')
    loadWorker()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '删除失败')
  }
}

onMounted(() => {
  window.addEventListener('resize', onResize)
  loadWorker()
})
onUnmounted(() => window.removeEventListener('resize', onResize))
</script>

<style scoped>
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.event-card {
  margin-bottom: 0;
}
.event-header {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.event-meta {
  font-size: 13px;
  color: #909399;
}
.event-desc {
  margin: 8px 0 4px;
  color: #606266;
  font-size: 14px;
}
.event-actions {
  margin-top: 8px;
}
</style>
