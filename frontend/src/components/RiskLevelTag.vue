<template>
  <el-tag :type="tagType" :effect="effect">{{ label }}</el-tag>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  level: { type: String, required: true },
  effect: { type: String, default: 'light' },
})

const levelMap = {
  low: { label: '低风险', type: 'success' },
  medium: { label: '中风险', type: 'warning' },
  high: { label: '高风险', type: 'danger' },
  critical: { label: '严重', type: 'danger' },
}

const tagType = computed(() => levelMap[props.level]?.type || 'info')
const label = computed(() => levelMap[props.level]?.label || props.level)
</script>

<style scoped>
.el-tag--danger {
  --el-tag-bg-color: var(--el-color-danger-light-9);
}
</style>
