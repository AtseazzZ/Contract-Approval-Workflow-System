<template>
  <div class="audit-log">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>审计日志</span>
          <el-button size="small" @click="loadData">刷新</el-button>
        </div>
      </template>

      <!-- 筛选 -->
      <el-form :inline="true" :model="filter" style="margin-bottom: 16px;">
        <el-form-item label="操作">
          <el-select v-model="filter.action" placeholder="全部" clearable style="width: 150px">
            <el-option label="提交" value="SUBMIT" />
            <el-option label="处理" value="PROCESS" />
            <el-option label="审批" value="APPROVE" />
            <el-option label="撤回" value="WITHDRAW" />
            <el-option label="删除" value="DELETE" />
          </el-select>
        </el-form-item>
        <el-form-item label="目标ID">
          <el-input v-model="filter.targetId" placeholder="合同ID" style="width: 120px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="operator" label="操作人" width="120" />
        <el-table-column prop="action" label="动作" width="100">
          <template #default="{ row }">
            <el-tag :type="actionTagType(row.action)" size="small">{{ row.action }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="targetType" label="目标类型" width="100" />
        <el-table-column prop="targetId" label="目标ID" width="80" />
        <el-table-column prop="outcome" label="结果" width="80">
          <template #default="{ row }">
            <el-tag :type="row.outcome === 'SUCCESS' ? 'success' : 'danger'" size="small">
              {{ row.outcome }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="detail" label="详情" min-width="250" show-overflow-tooltip />
        <el-table-column prop="createTime" label="时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.createTime) }}
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
          v-model:current-page="page.current"
          v-model:page-size="page.size"
          :total="page.total"
          :page-sizes="[20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { getAuditLogList } from '../api/contract'

const loading = ref(false)
const tableData = ref([])
const page = reactive({ current: 1, size: 20, total: 0 })
const filter = reactive({ action: '', targetId: '' })

async function loadData() {
  loading.value = true
  try {
    const res = await getAuditLogList({
      page: page.current,
      size: page.size,
      action: filter.action || undefined,
      targetId: filter.targetId || undefined,
      targetType: 'CONTRACT'
    })
    tableData.value = res.data.records || []
    page.total = res.data.total || 0
  } catch (e) {
    // 已处理
  } finally {
    loading.value = false
  }
}

function resetFilter() {
  filter.action = ''
  filter.targetId = ''
  page.current = 1
  loadData()
}

function actionTagType(action) {
  const map = { SUBMIT: 'primary', PROCESS: 'primary', APPROVE: 'success', WITHDRAW: 'warning', DELETE: 'danger' }
  return map[action] || ''
}

function formatTime(time) {
  if (!time) return ''
  return time.replace('T', ' ').substring(0, 19)
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.pagination {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
