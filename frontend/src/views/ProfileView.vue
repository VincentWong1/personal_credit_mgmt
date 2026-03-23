<template>
  <div>
    <h3 style="margin-bottom: 16px">个人设置</h3>
    <el-card class="profile-card">
      <template #header>修改密码</template>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="原密码" prop="old_password">
          <el-input v-model="form.old_password" type="password" show-password />
        </el-form-item>
        <el-form-item label="新密码" prop="new_password">
          <el-input v-model="form.new_password" type="password" show-password />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirm">
          <el-input v-model="form.confirm" type="password" show-password />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { authApi } from '../api/auth'
import { ElMessage } from 'element-plus'

const formRef = ref()
const saving = ref(false)

const form = reactive({ old_password: '', new_password: '', confirm: '' })
const rules = {
  old_password: [{ required: true, message: '请输入原密码', trigger: 'blur' }],
  new_password: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码至少6位', trigger: 'blur' },
  ],
  confirm: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    { validator: (_, val, cb) => val === form.new_password ? cb() : cb(new Error('两次密码不一致')), trigger: 'blur' },
  ],
}

async function handleSubmit() {
  await formRef.value.validate()
  saving.value = true
  try {
    await authApi.changePassword(form.old_password, form.new_password)
    ElMessage.success('密码修改成功')
    Object.assign(form, { old_password: '', new_password: '', confirm: '' })
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '修改失败')
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.profile-card { max-width: 500px; }
@media (max-width: 767px) {
  .profile-card { max-width: 100%; }
}
</style>
