<template>
  <div>
    <el-page-header @back="$router.back()" :title="isEdit ? '编辑风险事件' : '新增风险事件'" style="margin-bottom: 16px" />
    <el-card>
      <el-form ref="formRef" :model="form" :rules="rules" :label-width="isMobile ? '80px' : '100px'" class="form-content">
        <el-form-item v-if="needWorkerSelect" label="关联工人" prop="worker_id">
          <el-select
            v-model="form.worker_id"
            placeholder="输入姓名或身份证号搜索工人"
            filterable
            remote
            :remote-method="searchWorkers"
            :loading="workerSearching"
            style="width: 100%"
          >
            <el-option
              v-for="w in workerOptions"
              :key="w.id"
              :label="`${w.name}（${w.id_card_number}）`"
              :value="w.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="事件日期" prop="event_date">
          <el-date-picker v-model="form.event_date" type="date" placeholder="选择日期" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="风险等级" prop="risk_level">
          <el-select v-model="form.risk_level" placeholder="选择风险等级" style="width: 100%">
            <el-option label="低风险" value="low" />
            <el-option label="中风险" value="medium" />
            <el-option label="高风险" value="high" />
            <el-option label="严重" value="critical" />
          </el-select>
        </el-form-item>
        <el-form-item label="事件类别" prop="category">
          <el-select v-model="form.category" placeholder="选择事件类别" filterable allow-create style="width: 100%">
            <el-option v-for="cat in categories" :key="cat.id" :label="cat.name" :value="cat.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联单位">
          <el-select v-model="form.company_id" placeholder="选择或输入新单位（可选）" clearable filterable allow-create style="width: 100%" @change="handleCompanyChange">
            <el-option v-for="c in companies" :key="c.id" :label="c.name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联项目">
          <el-select v-model="form.project_id" placeholder="选择或输入新项目（可选）" clearable filterable allow-create style="width: 100%">
            <el-option v-for="p in projects" :key="p.id" :label="p.name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="事件描述">
          <el-input v-model="form.description" type="textarea" :rows="4" placeholder="请描述事件详情" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
          <el-button @click="$router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { eventsApi } from '../api/events'
import { commonApi } from '../api/common'
import { workersApi } from '../api/workers'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const windowWidth = ref(window.innerWidth)
const isMobile = computed(() => windowWidth.value < 768)
function onResize() { windowWidth.value = window.innerWidth }
const isEdit = computed(() => route.name === 'EventEdit')
// 从工人详情页进入时 route.name === 'EventNew'，带有 route.params.id 作为 worker_id
// 从全局入口进入时 route.name === 'EventNewGlobal'，需要手动选择工人
const hasWorkerInRoute = computed(() => route.name === 'EventNew')
const needWorkerSelect = computed(() => !isEdit.value && !hasWorkerInRoute.value)

const formRef = ref()
const saving = ref(false)
const categories = ref([])
const companies = ref([])
const projects = ref([])
const workerOptions = ref([])
const workerSearching = ref(false)

const form = reactive({
  worker_id: null,
  event_date: '',
  risk_level: '',
  category: '',
  description: '',
  company_id: null,
  project_id: null,
})

const rules = computed(() => {
  const base = {
    event_date: [{ required: true, message: '请选择事件日期', trigger: 'change' }],
    risk_level: [{ required: true, message: '请选择风险等级', trigger: 'change' }],
    category: [{ required: true, message: '请选择事件类别', trigger: 'change' }],
  }
  if (needWorkerSelect.value) {
    base.worker_id = [{ required: true, message: '请选择关联工人', trigger: 'change' }]
  }
  return base
})

async function searchWorkers(query) {
  if (!query) {
    workerOptions.value = []
    return
  }
  workerSearching.value = true
  try {
    const res = await workersApi.list({ q: query, page: 1, page_size: 10 })
    workerOptions.value = res.items
  } catch {} finally {
    workerSearching.value = false
  }
}

async function handleCompanyChange(companyId) {
  form.project_id = null
  if (companyId) {
    projects.value = await commonApi.getProjects(companyId)
  } else {
    projects.value = await commonApi.getProjects()
  }
}

onMounted(async () => {
  window.addEventListener('resize', onResize)
  try {
    const [cats, comps, projs] = await Promise.all([
      eventsApi.getCategories(),
      commonApi.getCompanies(),
      commonApi.getProjects(),
    ])
    categories.value = cats
    companies.value = comps
    projects.value = projs
  } catch {}

  if (isEdit.value) {
    try {
      const event = await eventsApi.get(route.params.id)
      form.worker_id = event.worker_id
      form.event_date = event.event_date
      form.risk_level = event.risk_level
      form.category = event.category
      form.description = event.description || ''
      form.company_id = event.company_id
      form.project_id = event.project_id
    } catch {
      ElMessage.error('加载事件信息失败')
    }
  }
})

async function resolveCompanyAndProject() {
  if (form.company_id && typeof form.company_id === 'string') {
    const created = await commonApi.createCompany(form.company_id)
    companies.value.push(created)
    form.company_id = created.id
  }
  if (form.project_id && typeof form.project_id === 'string') {
    const created = await commonApi.createProject({ name: form.project_id, company_id: form.company_id })
    projects.value.push(created)
    form.project_id = created.id
  }
}

async function handleSubmit() {
  await formRef.value.validate()
  saving.value = true
  try {
    await resolveCompanyAndProject()
    if (isEdit.value) {
      await eventsApi.update(route.params.id, form)
      ElMessage.success('更新成功')
      router.back()
    } else {
      const workerId = hasWorkerInRoute.value ? route.params.id : form.worker_id
      await eventsApi.create(workerId, form)
      ElMessage.success('新增成功')
      if (hasWorkerInRoute.value) {
        router.push(`/workers/${workerId}`)
      } else {
        router.push('/events')
      }
    }
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '保存失败')
  } finally {
    saving.value = false
  }
}

onUnmounted(() => window.removeEventListener('resize', onResize))
</script>

<style scoped>
.form-content { max-width: 600px; }
@media (max-width: 767px) {
  .form-content { max-width: 100%; }
}
</style>
