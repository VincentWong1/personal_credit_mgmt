<template>
  <div>
    <div class="page-header">
      <h3>用户管理</h3>
      <el-button type="primary" @click="showCreateDialog = true">新增用户</el-button>
    </div>

    <el-card>
      <el-table :data="users" v-loading="loading" stripe class="responsive-table">
        <el-table-column prop="username" label="用户名" min-width="100" />
        <el-table-column prop="display_name" label="显示名称" min-width="100" />
        <el-table-column prop="role" label="角色" min-width="80">
          <template #default="{ row }">
            <el-tag :type="roleType(row.role)">{{ roleLabel(row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="is_active" label="状态" min-width="70">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'info'">{{ row.is_active ? '正常' : '已停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" min-width="160" class-name="hidden-xs">
          <template #default="{ row }">{{ formatDate(row.created_at) }}</template>
        </el-table-column>
        <el-table-column label="操作" fixed="right" min-width="120">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEditDialog(row)">编辑</el-button>
            <el-popconfirm v-if="row.is_active" title="确定停用该用户？" @confirm="handleDisable(row.id)">
              <template #reference>
                <el-button link type="danger">停用</el-button>
              </template>
            </el-popconfirm>
            <el-button v-else link type="success" @click="handleEnable(row.id)">启用</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="total, prev, pager, next"
          @current-change="loadUsers"
        />
      </div>
    </el-card>

    <!-- Create Dialog -->
    <el-dialog v-model="showCreateDialog" title="新增用户" width="450px" :fullscreen="isMobile">
      <el-form ref="createFormRef" :model="createForm" :rules="createRules" label-width="80px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="createForm.username" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="createForm.password" type="password" show-password />
        </el-form-item>
        <el-form-item label="显示名称" prop="display_name">
          <el-input v-model="createForm.display_name" />
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="createForm.role" style="width: 100%">
            <el-option label="管理员" value="admin" />
            <el-option label="运维" value="operator" />
            <el-option label="普通用户" value="user" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleCreate">确定</el-button>
      </template>
    </el-dialog>

    <!-- Edit Dialog -->
    <el-dialog v-model="showEditDialog" title="编辑用户" width="450px" :fullscreen="isMobile">
      <el-form ref="editFormRef" :model="editForm" label-width="80px">
        <el-form-item label="用户名">
          <el-input :model-value="editForm.username" disabled />
        </el-form-item>
        <el-form-item label="显示名称">
          <el-input v-model="editForm.display_name" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="editForm.role" style="width: 100%">
            <el-option label="管理员" value="admin" />
            <el-option label="运维" value="operator" />
            <el-option label="普通用户" value="user" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEditDialog = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleUpdate">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { usersApi } from '../api/users'
import { ElMessage } from 'element-plus'

const windowWidth = ref(window.innerWidth)
const isMobile = computed(() => windowWidth.value < 768)
function onResize() { windowWidth.value = window.innerWidth }

const users = ref([])
const loading = ref(false)
const saving = ref(false)
const page = ref(1)
const pageSize = 20
const total = ref(0)

const showCreateDialog = ref(false)
const showEditDialog = ref(false)
const createFormRef = ref()
const editFormRef = ref()

const createForm = reactive({ username: '', password: '', display_name: '', role: 'user' })
const createRules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }, { min: 6, message: '密码至少6位', trigger: 'blur' }],
  display_name: [{ required: true, message: '请输入显示名称', trigger: 'blur' }],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }],
}

const editForm = reactive({ id: 0, username: '', display_name: '', role: '' })

const roleLabels = { admin: '管理员', operator: '运维', user: '普通用户' }
const roleTypes = { admin: 'danger', operator: 'warning', user: '' }
function roleLabel(r) { return roleLabels[r] || r }
function roleType(r) { return roleTypes[r] || '' }
function formatDate(d) { return d ? new Date(d).toLocaleString('zh-CN') : '' }

async function loadUsers() {
  loading.value = true
  try {
    const res = await usersApi.list({ page: page.value, page_size: pageSize })
    users.value = res.items
    total.value = res.total
  } catch { ElMessage.error('加载失败') }
  finally { loading.value = false }
}

async function handleCreate() {
  await createFormRef.value.validate()
  saving.value = true
  try {
    await usersApi.create(createForm)
    ElMessage.success('创建成功')
    showCreateDialog.value = false
    Object.assign(createForm, { username: '', password: '', display_name: '', role: 'user' })
    loadUsers()
  } catch (e) { ElMessage.error(e.response?.data?.detail || '创建失败') }
  finally { saving.value = false }
}

function openEditDialog(user) {
  Object.assign(editForm, { id: user.id, username: user.username, display_name: user.display_name, role: user.role })
  showEditDialog.value = true
}

async function handleUpdate() {
  saving.value = true
  try {
    await usersApi.update(editForm.id, { display_name: editForm.display_name, role: editForm.role })
    ElMessage.success('更新成功')
    showEditDialog.value = false
    loadUsers()
  } catch (e) { ElMessage.error(e.response?.data?.detail || '更新失败') }
  finally { saving.value = false }
}

async function handleDisable(id) {
  try {
    await usersApi.delete(id)
    ElMessage.success('用户已停用')
    loadUsers()
  } catch (e) { ElMessage.error(e.response?.data?.detail || '操作失败') }
}

async function handleEnable(id) {
  try {
    await usersApi.update(id, { is_active: true })
    ElMessage.success('用户已启用')
    loadUsers()
  } catch (e) { ElMessage.error(e.response?.data?.detail || '操作失败') }
}

onMounted(() => {
  window.addEventListener('resize', onResize)
  loadUsers()
})
onUnmounted(() => window.removeEventListener('resize', onResize))
</script>

<style scoped>
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-header h3 { margin: 0; }
.pagination-wrap { margin-top: 16px; display: flex; justify-content: flex-end; }
@media (max-width: 767px) {
  .page-header h3 { font-size: 16px; }
  :deep(.hidden-xs) { display: none !important; }
}
</style>
