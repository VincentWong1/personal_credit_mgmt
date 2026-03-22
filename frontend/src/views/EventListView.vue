<template>
  <div>
    <div class="page-header">
      <h3>风险事件</h3>
      <el-button v-if="auth.isOperator" type="primary" @click="$router.push('/events/new')">
        新增风险事件
      </el-button>
    </div>

    <el-card>
      <div class="filter-bar">
        <el-input
          v-model="filters.q"
          placeholder="搜索工人姓名"
          clearable
          :prefix-icon="Search"
          class="filter-input"
          @input="handleFilterChange"
          @clear="handleFilterChange"
        />
        <el-select v-model="filters.risk_level" placeholder="风险等级" clearable class="filter-select" @change="handleFilterChange">
          <el-option label="低风险" value="low" />
          <el-option label="中风险" value="medium" />
          <el-option label="高风险" value="high" />
          <el-option label="严重" value="critical" />
        </el-select>
        <el-select v-model="filters.category" placeholder="事件类别" clearable filterable class="filter-select" @change="handleFilterChange">
          <el-option v-for="cat in categories" :key="cat.id" :label="cat.name" :value="cat.name" />
        </el-select>
      </div>

      <el-table :data="events" v-loading="loading" stripe class="responsive-table">
        <el-table-column prop="worker_name" label="工人" min-width="80">
          <template #default="{ row }">
            <el-button link type="primary" @click="$router.push(`/workers/${row.worker_id}`)">{{ row.worker_name }}</el-button>
          </template>
        </el-table-column>
        <el-table-column prop="event_date" label="日期" min-width="100" />
        <el-table-column prop="risk_level" label="等级" min-width="80">
          <template #default="{ row }">
            <RiskLevelTag :level="row.risk_level" />
          </template>
        </el-table-column>
        <el-table-column prop="category" label="类别" min-width="90" />
        <el-table-column prop="company_name" label="关联单位" min-width="140" class-name="hidden-xs" />
        <el-table-column prop="description" label="描述" min-width="180" show-overflow-tooltip class-name="hidden-xs" />
        <el-table-column label="操作" fixed="right" min-width="100" v-if="auth.isOperator">
          <template #default="{ row }">
            <el-button link type="primary" @click="$router.push(`/events/${row.id}/edit`)">编辑</el-button>
            <el-popconfirm v-if="auth.isAdmin" title="确定删除该事件？" @confirm="handleDelete(row.id)">
              <template #reference>
                <el-button link type="danger">删除</el-button>
              </template>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="total, prev, pager, next"
          @current-change="loadEvents"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { eventsApi } from '../api/events'
import { ElMessage } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import RiskLevelTag from '../components/RiskLevelTag.vue'

const auth = useAuthStore()
const events = ref([])
const categories = ref([])
const loading = ref(false)
const page = ref(1)
const pageSize = 20
const total = ref(0)

let debounceTimer = null
const filters = reactive({ q: '', risk_level: '', category: '' })

async function loadEvents() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize }
    if (filters.q) params.q = filters.q
    if (filters.risk_level) params.risk_level = filters.risk_level
    if (filters.category) params.category = filters.category
    const res = await eventsApi.list(params)
    events.value = res.items
    total.value = res.total
  } catch {
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}

function handleFilterChange() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    page.value = 1
    loadEvents()
  }, 300)
}

async function handleDelete(id) {
  try {
    await eventsApi.delete(id)
    ElMessage.success('事件已删除')
    loadEvents()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '删除失败')
  }
}

onMounted(async () => {
  try {
    categories.value = await eventsApi.getCategories()
  } catch {}
  loadEvents()
})
</script>

<style scoped>
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.page-header h3 { margin: 0; }
.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}
.filter-input {
  width: 220px;
}
.filter-select {
  width: 140px;
}
.pagination-wrap {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
@media (max-width: 767px) {
  .page-header h3 { font-size: 16px; }
  .filter-input, .filter-select { width: 100%; }
  :deep(.hidden-xs) { display: none !important; }
}
</style>
