<template>
  <div>
    <div class="page-header">
      <h3>工人管理</h3>
      <el-button v-if="auth.isOperator" type="primary" @click="$router.push('/workers/new')">
        新增工人
      </el-button>
    </div>

    <el-card>
      <div style="margin-bottom: 16px">
        <SearchBar @search="handleSearch" />
      </div>
      <el-table :data="workers" v-loading="loading" stripe class="responsive-table">
        <el-table-column prop="name" label="姓名" min-width="80" />
        <el-table-column prop="id_card_number" label="身份证号" min-width="180" class-name="hidden-xs" />
        <el-table-column prop="gender" label="性别" width="60" class-name="hidden-xs">
          <template #default="{ row }">{{ row.gender === 'male' ? '男' : '女' }}</template>
        </el-table-column>
        <el-table-column prop="risk_event_count" label="风险事件" min-width="80">
          <template #default="{ row }">
            <el-tag v-if="row.risk_event_count > 0" type="danger">{{ row.risk_event_count }}</el-tag>
            <span v-else>0</span>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" min-width="160" class-name="hidden-xs">
          <template #default="{ row }">{{ formatDate(row.created_at) }}</template>
        </el-table-column>
        <el-table-column label="操作" fixed="right" min-width="120">
          <template #default="{ row }">
            <el-button link type="primary" @click="$router.push(`/workers/${row.id}`)">详情</el-button>
            <el-button v-if="auth.isOperator" link type="primary" @click="$router.push(`/workers/${row.id}/edit`)">编辑</el-button>
            <el-popconfirm v-if="auth.isAdmin" title="确定删除该工人？" @confirm="handleDelete(row.id)">
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
          @current-change="loadWorkers"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { workersApi } from '../api/workers'
import { ElMessage } from 'element-plus'
import SearchBar from '../components/SearchBar.vue'

const auth = useAuthStore()
const workers = ref([])
const loading = ref(false)
const page = ref(1)
const pageSize = 20
const total = ref(0)
const searchQuery = ref('')

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleString('zh-CN')
}

async function loadWorkers() {
  loading.value = true
  try {
    const res = await workersApi.list({ q: searchQuery.value, page: page.value, page_size: pageSize })
    workers.value = res.items
    total.value = res.total
  } catch {
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}

function handleSearch(q) {
  searchQuery.value = q
  page.value = 1
  loadWorkers()
}

async function handleDelete(id) {
  try {
    await workersApi.delete(id)
    ElMessage.success('删除成功')
    loadWorkers()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '删除失败')
  }
}

onMounted(loadWorkers)
</script>

<style scoped>
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.page-header h3 { margin: 0; }
.pagination-wrap {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
@media (max-width: 767px) {
  .page-header h3 { font-size: 16px; }
  :deep(.hidden-xs) { display: none !important; }
}
</style>
