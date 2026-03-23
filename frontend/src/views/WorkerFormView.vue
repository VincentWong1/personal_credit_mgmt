<template>
  <div>
    <el-page-header @back="$router.back()" :title="isEdit ? '编辑工人' : '新增工人'" style="margin-bottom: 16px" />
    <el-card>
      <el-form ref="formRef" :model="form" :rules="rules" :label-width="isMobile ? '80px' : '100px'" class="form-content">
        <el-form-item label="身份证号" prop="id_card_number">
          <IdCardInput
            v-model="form.id_card_number"
            :disabled="isEdit"
            @gender-detected="(g) => (form.gender = g)"
          />
        </el-form-item>
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="请输入姓名" />
        </el-form-item>
        <el-form-item label="性别">
          <el-radio-group v-model="form.gender" :disabled="!!form.id_card_number && form.id_card_number.length === 18">
            <el-radio value="male">男</el-radio>
            <el-radio value="female">女</el-radio>
          </el-radio-group>
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
import { workersApi } from '../api/workers'
import { ElMessage } from 'element-plus'
import IdCardInput from '../components/IdCardInput.vue'
import { validateIdCard } from '../utils/id-card'

const route = useRoute()
const router = useRouter()
const windowWidth = ref(window.innerWidth)
const isMobile = computed(() => windowWidth.value < 768)
function onResize() { windowWidth.value = window.innerWidth }
const isEdit = computed(() => !!route.params.id)
const formRef = ref()
const saving = ref(false)

const form = reactive({
  id_card_number: '',
  name: '',
  gender: 'male',
})

const rules = {
  id_card_number: [
    { required: true, message: '请输入身份证号', trigger: 'blur' },
    { validator: (_, val, cb) => validateIdCard(val) ? cb() : cb(new Error('身份证号格式不正确')), trigger: 'blur' },
  ],
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
}

onMounted(async () => {
  window.addEventListener('resize', onResize)
  if (isEdit.value) {
    try {
      const w = await workersApi.get(route.params.id)
      form.id_card_number = w.id_card_number
      form.name = w.name
      form.gender = w.gender
    } catch {
      ElMessage.error('加载工人信息失败')
    }
  }
})

async function handleSubmit() {
  await formRef.value.validate()
  saving.value = true
  try {
    if (isEdit.value) {
      await workersApi.update(route.params.id, { name: form.name })
      ElMessage.success('更新成功')
    } else {
      await workersApi.create(form)
      ElMessage.success('新增成功')
    }
    router.push('/workers')
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
