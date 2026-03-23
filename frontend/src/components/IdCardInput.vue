<template>
  <el-input
    v-model="inputValue"
    :placeholder="placeholder"
    maxlength="18"
    @input="handleInput"
    @blur="handleBlur"
  >
    <template #append v-if="gender">
      {{ gender === 'male' ? '男' : '女' }}
    </template>
  </el-input>
  <div v-if="error" class="id-card-error">{{ error }}</div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { validateIdCard, extractGender } from '../utils/id-card'

const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: { type: String, default: '请输入18位身份证号' },
})

const emit = defineEmits(['update:modelValue', 'gender-detected'])

const inputValue = ref(props.modelValue)
const error = ref('')
const gender = ref('')

watch(() => props.modelValue, (val) => {
  inputValue.value = val
})

function handleInput(val) {
  inputValue.value = val.replace(/[^\dXx]/g, '').substring(0, 18)
  emit('update:modelValue', inputValue.value)
  error.value = ''

  if (inputValue.value.length === 18) {
    if (validateIdCard(inputValue.value)) {
      gender.value = extractGender(inputValue.value)
      emit('gender-detected', gender.value)
    } else {
      error.value = '身份证号校验不通过'
      gender.value = ''
    }
  } else {
    gender.value = ''
  }
}

function handleBlur() {
  if (inputValue.value && inputValue.value.length !== 18) {
    error.value = '身份证号需要18位'
  }
}
</script>

<style scoped>
.id-card-error {
  color: var(--el-color-danger);
  font-size: 12px;
  margin-top: 4px;
}
</style>
