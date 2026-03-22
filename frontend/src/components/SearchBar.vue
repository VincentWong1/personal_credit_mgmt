<template>
  <el-input
    v-model="query"
    :placeholder="placeholder"
    clearable
    :prefix-icon="Search"
    @input="handleInput"
    @clear="handleClear"
    style="max-width: 400px"
  />
</template>

<script setup>
import { ref, onUnmounted } from 'vue'
import { Search } from '@element-plus/icons-vue'

const props = defineProps({
  placeholder: { type: String, default: '输入姓名或身份证号搜索' },
  delay: { type: Number, default: 300 },
})

const emit = defineEmits(['search'])

const query = ref('')
let timer = null

function handleInput() {
  clearTimeout(timer)
  timer = setTimeout(() => {
    emit('search', query.value)
  }, props.delay)
}

function handleClear() {
  emit('search', '')
}

onUnmounted(() => clearTimeout(timer))
</script>
