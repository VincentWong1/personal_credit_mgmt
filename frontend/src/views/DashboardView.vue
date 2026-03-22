<template>
  <div class="dashboard">
    <el-row :gutter="16" class="stat-row">
      <el-col :xs="24" :sm="8">
        <el-card shadow="hover">
          <el-statistic title="工人总数" :value="stats.worker_count" />
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="8">
        <el-card shadow="hover">
          <el-statistic title="风险事件总数" :value="stats.event_count" />
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="8">
        <el-card shadow="hover">
          <el-statistic title="关联单位数" :value="stats.company_count" />
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" style="margin-top: 16px">
      <el-col :xs="24" :sm="12">
        <el-card>
          <template #header>风险等级分布</template>
          <div class="risk-bars">
            <div v-for="item in riskItems" :key="item.key" class="risk-bar-item">
              <span class="risk-label">{{ item.label }}</span>
              <el-progress
                :percentage="item.percentage"
                :color="item.color"
                :format="() => item.count + ''"
                style="flex: 1"
              />
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12">
        <el-card>
          <template #header>事件类别统计（前10）</template>
          <div v-if="stats.category_distribution?.length">
            <div v-for="cat in stats.category_distribution" :key="cat.name" class="cat-item">
              <span>{{ cat.name }}</span>
              <el-tag>{{ cat.count }}</el-tag>
            </div>
          </div>
          <el-empty v-else description="暂无数据" :image-size="60" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { commonApi } from '../api/common'

const stats = ref({
  worker_count: 0,
  event_count: 0,
  company_count: 0,
  risk_distribution: {},
  category_distribution: [],
})

const riskLevels = [
  { key: 'low', label: '低风险', color: '#67c23a' },
  { key: 'medium', label: '中风险', color: '#e6a23c' },
  { key: 'high', label: '高风险', color: '#f56c6c' },
  { key: 'critical', label: '严重', color: '#8b0000' },
]

const totalEvents = computed(() => {
  return Object.values(stats.value.risk_distribution || {}).reduce((a, b) => a + b, 0) || 1
})

const riskItems = computed(() =>
  riskLevels.map((l) => ({
    ...l,
    count: stats.value.risk_distribution?.[l.key] || 0,
    percentage: Math.round(((stats.value.risk_distribution?.[l.key] || 0) / totalEvents.value) * 100),
  }))
)

onMounted(async () => {
  try {
    stats.value = await commonApi.getStats()
  } catch {}
})
</script>

<style scoped>
.stat-row .el-card {
  text-align: center;
}
.risk-bars {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.risk-bar-item {
  display: flex;
  align-items: center;
  gap: 12px;
}
.risk-label {
  width: 50px;
  text-align: right;
  font-size: 14px;
}
.cat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}
.cat-item:last-child {
  border-bottom: none;
}
@media (max-width: 767px) {
  .stat-row .el-col {
    margin-bottom: 12px;
  }
}
</style>
